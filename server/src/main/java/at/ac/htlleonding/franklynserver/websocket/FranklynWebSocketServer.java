package at.ac.htlleonding.franklynserver.websocket;

import at.ac.htlleonding.franklynserver.cache.Cache;
import at.ac.htlleonding.franklynserver.cache.FrameListener;
import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.model.*;
import at.ac.htlleonding.franklynserver.oidc.UserRole;
import at.ac.htlleonding.franklynserver.repository.exam.ExamDao;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.logging.Log;
import io.quarkus.websockets.next.*;
import io.smallrye.jwt.auth.principal.JWTParser;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@WebSocket(path = "/ws/{service}")
public class FranklynWebSocketServer {

    private static final String SERVICE_SENTINEL = "sentinel";
    private static final String SERVICE_PROCTOR = "proctor";
    private static final String ROLE_STUDENT = "student";
    private static final String ROLE_TEACHER = "teacher";
    private static final String ROLE_ADMIN = "franklyn-admin";

    @Inject
    ObjectMapper objectMapper;

    @Inject
    Cache frameCache;

    @Inject
    ExamDao examDao;

    @Inject
    FranklynConfig config;

    @Inject
    JWTParser jwtParser;

    private final Map<String, WebSocketConnection> sentinelConnections = new ConcurrentHashMap<>();
    private final Map<String, String> sentinelNames = new ConcurrentHashMap<>();
    private final Map<String, Integer> sentinelPins = new ConcurrentHashMap<>();
    private final Map<String, WebSocketConnection> proctorConnections = new ConcurrentHashMap<>();
    private final Map<String, Integer> proctorPinFilters = new ConcurrentHashMap<>();
    private final Map<String, AuthenticatedUser> authenticatedSessions = new ConcurrentHashMap<>();

    private final Map<String, Set<FrameListener>> proctorListeners = new ConcurrentHashMap<>();
    private final Map<WebSocketConnection, String> proctorSentinelReverse = new ConcurrentHashMap<>();

    // New Connection
    @OnOpen
    public void onOpen(WebSocketConnection connection) {
        String service = connection.pathParam("service");
        Log.infof("New connection as: %s (ID: %s)", service, connection.id());
    }

    // Routes incoming messages to appropriate franklyn-service
    @OnTextMessage
    public void onMessage(String jsonMessage, WebSocketConnection connection) {
        String service = connection.pathParam("service");
        try {
            WsMessage msg = objectMapper.readValue(jsonMessage, WsMessage.class);

            if (SERVICE_SENTINEL.equals(service)) {
                handleSentinelMessage(msg, connection);
            } else if (SERVICE_PROCTOR.equals(service)) {
                handleProctorMessage(msg, connection);
            }
        } catch (Exception e) {
            Log.error("JSON Error: " + e.getMessage());
        }
    }

    // Processes sentinel registration and frames
    private void handleSentinelMessage(WsMessage msg, WebSocketConnection connection) throws Exception {
        switch (msg.type()) {
            case "sentinel.register":
                if (isConnectionAuthenticated(connection)) {
                    return;
                }

                SentinelRegisterPayload registerPayload = objectMapper.convertValue(msg.payload(),
                        SentinelRegisterPayload.class);
                if (registerPayload == null) {
                    rejectRegistration(connection, "Invalid registration payload");
                    break;
                }
                int pin = registerPayload.pin();
                AuthenticatedUser authenticatedUser;
                try {
                    authenticatedUser = authenticate(registerPayload.auth());
                } catch (WebSocketException e) {
                    rejectRegistration(connection, e.getMessage());
                    break;
                }

                if (!authenticatedUser.hasRole(ROLE_STUDENT)) {
                    rejectRegistration(connection, "Insufficient permissions for sentinel");
                    break;
                }

                if (pin < config.pin().min() || pin > config.pin().max()) {
                    rejectRegistration(connection,
                            "PIN must be between " + config.pin().min() + " and " + config.pin().max());
                    break;
                }

                if (examDao.findByPin(pin).isEmpty()) {
                    rejectRegistration(connection, "No Exam found with this pin");
                    break;
                }

                authenticatedSessions.put(connection.id(), authenticatedUser);

                String sentinelId = UUID.randomUUID().toString();
                sentinelConnections.put(sentinelId, connection);
                sentinelPins.put(sentinelId, pin);

                String name = authenticatedUser.fullName();
                sentinelNames.put(sentinelId, name);

                sendJson(connection, "server.registration.ack", new SentinelAckPayload(sentinelId));
                broadcastSentinelList();
                break;

            case "sentinel.frame":
                if (!isConnectionAuthenticated(connection)) {
                    connection.closeAndAwait();
                    break;
                }
                processIncomingFrames(msg);
                break;

            default:
                throw new WebSocketException(String.format("Invalid sentinel message '%s'", msg.type()));
        }
    }

    // Processes proctor registration and subscriptions
    private void handleProctorMessage(WsMessage msg, WebSocketConnection connection) throws Exception {
        String proctorId = connection.id();

        switch (msg.type()) {
            case "proctor.register":
                if (isConnectionAuthenticated(connection)) {
                    return;
                }

                ProctorRegisterPayload proctorRegisterPayload = objectMapper.convertValue(msg.payload(),
                        ProctorRegisterPayload.class);
                if (proctorRegisterPayload == null) {
                    rejectRegistration(connection, "Invalid registration payload");
                    break;
                }
                AuthenticatedUser authenticatedUser;
                try {
                    authenticatedUser = authenticate(proctorRegisterPayload.auth());
                } catch (WebSocketException e) {
                    rejectRegistration(connection, e.getMessage());
                    break;
                }

                if (!authenticatedUser.hasAnyRole(ROLE_TEACHER, ROLE_ADMIN)) {
                    rejectRegistration(connection, "Insufficient permissions for proctor");
                    break;
                }

                authenticatedSessions.put(connection.id(), authenticatedUser);
                proctorConnections.put(proctorId, connection);
                sendJson(connection, "server.registration.ack", new RegistrationAckPayload(proctorId));
                sendCurrentSentinelList(connection);
                break;

            case "proctor.set-pin":
                if (!isConnectionAuthenticated(connection)) {
                    connection.closeAndAwait();
                    break;
                }
                SetPinPayload setPinPayload = objectMapper.convertValue(msg.payload(), SetPinPayload.class);
                Integer proctorPin = setPinPayload.pin();
                if (proctorPin != null && proctorPin >= config.pin().min() && proctorPin <= config.pin().max()) {
                    proctorPinFilters.put(proctorId, proctorPin);
                    sendCurrentSentinelList(connection);
                }
                break;

            case "proctor.subscribe":
                if (!isConnectionAuthenticated(connection)) {
                    connection.closeAndAwait();
                    break;
                }
                String sentinelIdToSubscribe = getSentinelIdFromPayload(msg.payload());

                if (sentinelIdToSubscribe != null) {
                    Integer pinFilter = proctorPinFilters.get(proctorId);
                    Integer sentinelPin = sentinelPins.get(sentinelIdToSubscribe);

                    if (pinFilter != null && !pinFilter.equals(sentinelPin)) {
                        Log.warnf("Proctor %s attempted to subscribe to sentinel %s with non-matching PIN", proctorId,
                                sentinelIdToSubscribe);
                        break;
                    }

                    UUID sentinelUuid = UUID.fromString(sentinelIdToSubscribe);
                    sendCachedFrameToProctor(connection, sentinelUuid);

                    FrameListener listener = new FrameListener(sentinelUuid, frame -> {
                        sendJson(connection, "server.frame", new FramesPayload(List.of(frame)));
                    });

                    frameCache.registerOnFrame(listener);
                    proctorListeners.computeIfAbsent(proctorId, k -> ConcurrentHashMap.newKeySet()).add(listener);
                    proctorSentinelReverse.put(connection, sentinelIdToSubscribe);
                }
                break;

            case "proctor.revoke-subscription":
                if (!isConnectionAuthenticated(connection)) {
                    connection.closeAndAwait();
                    break;
                }
                String sentinelIdToUnsubscribe = getSentinelIdFromPayload(msg.payload());

                if (sentinelIdToUnsubscribe != null) {
                    UUID sentinelUuid = UUID.fromString(sentinelIdToUnsubscribe);
                    Set<FrameListener> listeners = proctorListeners.get(proctorId);
                    if (listeners != null) {
                        listeners.removeIf(listener -> {
                            if (listener.sentinelId().equals(sentinelUuid)) {
                                frameCache.unregisterOnFrame(listener);
                                return true;
                            }
                            return false;
                        });
                    }
                    proctorSentinelReverse.remove(connection);
                }
                break;

            case "proctor.set-profile":
                if (!isConnectionAuthenticated(connection)) {
                    connection.closeAndAwait();
                    break;
                }
                SetProfilePayload setProfilePayload = objectMapper.convertValue(msg.payload(), SetProfilePayload.class);
                String targetSentinelId = setProfilePayload.sentinelId();
                String profile = setProfilePayload.profile();

                if (targetSentinelId != null && profile != null) {
                    WebSocketConnection sentinelConnection = sentinelConnections.get(targetSentinelId);
                    if (sentinelConnection != null) {
                        int maxSidePx = profileToMaxSidePx(profile);
                        sendJson(sentinelConnection, "server.set-resolution", new SetResolutionPayload(maxSidePx));
                        Log.infof("Sent set-resolution to sentinel %s with maxSidePx=%d (profile=%s)", targetSentinelId,
                                maxSidePx, profile);
                    } else {
                        Log.warnf("Sentinel %s not found for set-profile request", targetSentinelId);
                    }
                }
                break;

            default:
                connection.closeAndAwait();
                throw new WebSocketException(String.format("Invalid proctor message '%s'", msg.type()));
        }
    }

    private int profileToMaxSidePx(String profile) {
        return Profiles.stringify(profile).getMaxSidePx();
    }

    private void processIncomingFrames(WsMessage sentinelFrameMsg) {
        FramesPayload framesPayload = objectMapper.convertValue(sentinelFrameMsg.payload(), FramesPayload.class);
        for (Frame frame : framesPayload.frames()) {
            frameCache.saveFrame(frame, UUID.fromString(frame.sentinelId()));
        }
    }

    private void sendCachedFrameToProctor(WebSocketConnection connection, UUID sentinelId) {
        frameCache.getFrame(sentinelId).ifPresent(frame -> {
            sendJson(connection, "server.frame", new FramesPayload(List.of(frame)));
        });
    }

    @OnClose
    public void onClose(WebSocketConnection connection) {
        String connectionId = connection.id();

        // Cleanup Proctor
        proctorConnections.remove(connectionId);
        proctorPinFilters.remove(connectionId);
        Set<FrameListener> listeners = proctorListeners.remove(connectionId);
        if (listeners != null) {
            listeners.forEach(frameCache::unregisterOnFrame);
        }
        proctorSentinelReverse.remove(connection);
        authenticatedSessions.remove(connectionId);

        // Cleanup Sentinels
        sentinelConnections.entrySet().removeIf(entry -> {
            if (entry.getValue().equals(connection)) {
                sentinelNames.remove(entry.getKey());
                sentinelPins.remove(entry.getKey());
                return true;
            }
            return false;
        });

        broadcastSentinelList();
    }

    private void sendJson(WebSocketConnection connection, String type, Object payload) {
        try {
            WsMessage msg = new WsMessage(type, Instant.now().getEpochSecond(), payload);
            connection.sendText(objectMapper.writeValueAsString(msg)).subscribe().with(success -> {
            }, failure -> Log.errorf("Failed to send JSON message: %s", failure.getMessage()));
        } catch (Exception e) {
            Log.errorf("Failed to send JSON message: %s", e.getMessage());
        }
    }

    private List<SentinelInfo> buildSentinelInfoList() {
        return sentinelConnections.keySet().stream().map(id -> new SentinelInfo(id, sentinelNames.getOrDefault(id, "")))
                .toList();
    }

    private List<SentinelInfo> buildSentinelInfoList(Integer pinFilter) {
        return sentinelConnections.entrySet().stream().filter(entry -> {
            if (pinFilter == null)
                return true;
            Integer sentinelPin = sentinelPins.get(entry.getKey());
            return pinFilter.equals(sentinelPin);
        }).map(entry -> new SentinelInfo(entry.getKey(), sentinelNames.getOrDefault(entry.getKey(), ""))).toList();
    }

    private void broadcastSentinelList() {
        proctorConnections.forEach((proctorId, conn) -> {
            Integer pinFilter = proctorPinFilters.get(proctorId);
            UpdateSentinelsPayload payload = new UpdateSentinelsPayload(buildSentinelInfoList(pinFilter));
            sendJson(conn, "server.update-sentinels", payload);
        });
    }

    private void sendCurrentSentinelList(WebSocketConnection connection) {
        String proctorId = connection.id();
        Integer pinFilter = proctorPinFilters.get(proctorId);
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(buildSentinelInfoList(pinFilter));
        sendJson(connection, "server.update-sentinels", payload);
    }

    private String getSentinelIdFromPayload(Object payload) {
        if (payload instanceof Map<?, ?> map) {
            Object sentinelId = map.get("sentinelId");
            return sentinelId != null ? sentinelId.toString() : null;
        }
        return null;
    }

    private boolean isConnectionAuthenticated(WebSocketConnection connection) {
        return authenticatedSessions.containsKey(connection.id());
    }

    private void rejectRegistration(WebSocketConnection connection, String reason) {
        Log.warnf("Rejecting %s connection %s: %s", connection.pathParam("service"), connection.id(), reason);
        sendJson(connection, "server.registration.reject", new RegistrationRejectPayload(reason));
        try {
            connection.closeAndAwait();
        } catch (Exception e) {
            Log.debugf("Ignoring websocket close failure for %s: %s", connection.id(), e.getMessage());
        }
    }

    private AuthenticatedUser authenticate(String authToken) {
        if (authToken == null || authToken.isBlank()) {
            throw new WebSocketException("Missing auth token");
        }

        try {
            var jwt = jwtParser.parse(authToken);
            Set<String> roles = Optional.ofNullable(jwt.getGroups()).map(HashSet::new).orElseGet(HashSet::new);
            String ldapEntryDn = jwt.getClaim("distinguished_name");
            UserRole.fromDistinguishedName(ldapEntryDn).ifPresent(role -> roles.add(role.roleName()));

            return new AuthenticatedUser(
                    jwt.getSubject(),
                    jwt.getClaim("given_name"),
                    jwt.getClaim("family_name"),
                    roles);
        } catch (Exception e) {
            Log.warnf("JWT parsing failed: %s", e.getMessage());
            throw new WebSocketException("Invalid auth token", e);
        }
    }

    private record AuthenticatedUser(String subject, String givenName, String familyName, Set<String> roles) {
        private String fullName() {
            return ((givenName != null ? givenName : "") + " " + (familyName != null ? familyName : "")).trim();
        }

        private boolean hasRole(String role) {
            return roles.contains(role);
        }

        private boolean hasAnyRole(String... requiredRoles) {
            for (String role : requiredRoles) {
                if (roles.contains(role)) {
                    return true;
                }
            }
            return false;
        }
    }
}

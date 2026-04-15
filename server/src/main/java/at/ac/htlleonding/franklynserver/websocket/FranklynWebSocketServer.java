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
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
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
    private static final String KEYCLOAK_USERINFO_PATH = "/protocol/openid-connect/userinfo";
    private static final int HTTP_STATUS_SUCCESS_MIN = 200;
    private static final int HTTP_STATUS_SUCCESS_MAX_EXCLUSIVE = 300;

    @Inject
    ObjectMapper objectMapper;

    @Inject
    Cache frameCache;

    @Inject
    ExamDao examDao;

    @Inject
    FranklynConfig config;

    @Inject
    @ConfigProperty(name = "quarkus.oidc.auth-server-url")
    String oidcAuthServerUrl;

    @ConfigProperty(name = "quarkus.oidc.client-id")
    String oidcClientId;

    private final HttpClient httpClient = HttpClient.newHttpClient();

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

                if (!authenticatedUser.hasAnyRoleOrUnknown(ROLE_STUDENT, ROLE_TEACHER, ROLE_ADMIN)) {
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
                String proctorAuthToken = resolveAuthToken(
                        proctorRegisterPayload != null ? proctorRegisterPayload.auth() : null,
                        connection);
                if (proctorAuthToken == null || proctorAuthToken.isBlank()) {
                    rejectRegistration(connection, "Invalid registration payload");
                    break;
                }
                AuthenticatedUser authenticatedUser;
                try {
                    authenticatedUser = authenticate(proctorAuthToken);
                } catch (WebSocketException e) {
                    rejectRegistration(connection, e.getMessage());
                    break;
                }

                if (!authenticatedUser.hasAnyRoleOrUnknown(ROLE_TEACHER, ROLE_ADMIN)) {
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
            Map<String, Object> userInfo = fetchOidcUserInfo(authToken);
            Set<String> roles = collectRoles(
                    userInfo.get("groups"),
                    userInfo.get("realm_access"),
                    userInfo.get("resource_access"));
            String ldapEntryDn = asString(userInfo.get("distinguished_name"));
            roleFromDistinguishedName(ldapEntryDn).ifPresent(role -> roles.add(role.roleName()));

            String subject = asString(userInfo.get("sub"));
            if (subject == null || subject.isBlank()) {
                throw new IllegalStateException("Missing 'sub' claim in OIDC userinfo response");
            }

            return new AuthenticatedUser(
                    subject,
                    asString(userInfo.get("given_name")),
                    asString(userInfo.get("family_name")),
                    roles);
        } catch (Exception oidcError) {
            Log.warnf("OIDC userinfo validation failed: %s", oidcError.getMessage());
            throw new WebSocketException("Invalid auth token", oidcError);
        }
    }

    private Map<String, Object> fetchOidcUserInfo(String authToken) throws Exception {
        String userInfoUrl = oidcAuthServerUrl + KEYCLOAK_USERINFO_PATH;
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(userInfoUrl))
                .header("Authorization", "Bearer " + authToken)
                .header("Accept", "application/json")
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < HTTP_STATUS_SUCCESS_MIN
                || response.statusCode() >= HTTP_STATUS_SUCCESS_MAX_EXCLUSIVE) {
            throw new IllegalStateException("UserInfo endpoint returned HTTP " + response.statusCode());
        }

        return objectMapper.readValue(response.body(), Map.class);
    }

    private Set<String> collectRoles(Object groupsClaim, Object realmAccessClaim, Object resourceAccessClaim) {
        Set<String> roles = new HashSet<>();

        extractStringCollection(groupsClaim).forEach(role -> normalizeRole(role).ifPresent(roles::add));
        extractRolesFromAccessClaim(realmAccessClaim).forEach(role -> normalizeRole(role).ifPresent(roles::add));
        extractRolesFromResourceAccess(resourceAccessClaim).forEach(role -> normalizeRole(role).ifPresent(roles::add));

        return roles;
    }

    private Set<String> extractRolesFromAccessClaim(Object accessClaim) {
        Set<String> roles = new HashSet<>();
        if (accessClaim instanceof Map<?, ?> map) {
            extractStringCollection(map.get("roles")).forEach(roles::add);
        }
        return roles;
    }

    private Set<String> extractRolesFromResourceAccess(Object resourceAccessClaim) {
        Set<String> roles = new HashSet<>();
        if (resourceAccessClaim instanceof Map<?, ?> resources) {
            Object backendClientRoles = resources.get(oidcClientId);
            roles.addAll(extractRolesFromAccessClaim(backendClientRoles));
        }
        return roles;
    }

    private Set<String> extractStringCollection(Object claim) {
        Set<String> values = new HashSet<>();
        if (claim instanceof Collection<?> collection) {
            collection.stream().filter(Objects::nonNull).map(Object::toString).forEach(values::add);
        }
        return values;
    }

    private Optional<String> normalizeRole(String role) {
        if (role == null || role.isBlank()) {
            return Optional.empty();
        }

        String normalized = role.trim().toLowerCase(Locale.ROOT);
        if (normalized.equals("student") || normalized.equals("students")) {
            return Optional.of(ROLE_STUDENT);
        }
        if (normalized.equals("teacher") || normalized.equals("teachers")) {
            return Optional.of(ROLE_TEACHER);
        }
        if (normalized.equals(ROLE_ADMIN) || normalized.equals("franklyn_admin")) {
            return Optional.of(ROLE_ADMIN);
        }
        return Optional.empty();
    }

    private Optional<UserRole> roleFromDistinguishedName(String ldapEntryDn) {
        if (ldapEntryDn == null || ldapEntryDn.isBlank()) {
            return Optional.empty();
        }

        String normalizedDn = ldapEntryDn.toLowerCase(Locale.ROOT);
        if (normalizedDn.contains("ou=teacher") || normalizedDn.contains("ou=teachers")) {
            return Optional.of(UserRole.TEACHER);
        }
        if (normalizedDn.contains("ou=student") || normalizedDn.contains("ou=students")) {
            return Optional.of(UserRole.STUDENT);
        }
        return Optional.empty();
    }

    private Set<String> extractGroups(Object groupsClaim) {
        Set<String> groups = new HashSet<>();
        if (groupsClaim instanceof Collection<?> collection) {
            collection.stream().filter(Objects::nonNull).map(Object::toString).forEach(groups::add);
        }
        return groups;
    }

    private String asString(Object value) {
        return value != null ? value.toString() : null;
    }

    private String resolveAuthToken(String payloadToken, WebSocketConnection connection) {
        if (payloadToken != null && !payloadToken.isBlank()) {
            return payloadToken;
        }

        String authorizationHeader = connection.handshakeRequest().header("Authorization");
        if (authorizationHeader == null || authorizationHeader.isBlank()) {
            return null;
        }

        String prefix = "Bearer ";
        if (authorizationHeader.regionMatches(true, 0, prefix, 0, prefix.length())) {
            return authorizationHeader.substring(prefix.length()).trim();
        }

        return null;
    }

    private record AuthenticatedUser(String subject, String givenName, String familyName, Set<String> roles) {
        private String fullName() {
            return ((givenName != null ? givenName : "") + " " + (familyName != null ? familyName : "")).trim();
        }

        private boolean hasRole(String role) {
            return roles.contains(role);
        }

        private boolean hasRoleOrUnknown(String role) {
            return roles.isEmpty() || hasRole(role);
        }

        private boolean hasAnyRole(String... requiredRoles) {
            for (String role : requiredRoles) {
                if (roles.contains(role)) {
                    return true;
                }
            }
            return false;
        }

        private boolean hasAnyRoleOrUnknown(String... requiredRoles) {
            return roles.isEmpty() || hasAnyRole(requiredRoles);
        }
    }
}

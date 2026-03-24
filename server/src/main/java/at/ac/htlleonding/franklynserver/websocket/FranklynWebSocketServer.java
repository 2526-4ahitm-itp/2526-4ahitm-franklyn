package at.ac.htlleonding.franklynserver.websocket;

import at.ac.htlleonding.franklynserver.cache.Cache;
import at.ac.htlleonding.franklynserver.cache.FrameListener;
import at.ac.htlleonding.franklynserver.model.*;
import at.ac.htlleonding.franklynserver.repository.test.TestDao;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.logging.Log;
import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.websockets.next.*;
import org.eclipse.microprofile.jwt.JsonWebToken;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@WebSocket(path = "/ws/{service}")
@RolesAllowed({"teacher", "student", "franklyn-admin"})
public class FranklynWebSocketServer {

    private static final String SERVICE_SENTINEL = "sentinel";
    private static final String SERVICE_PROCTOR = "proctor";

    @Inject
    ObjectMapper objectMapper;

    @Inject
    Cache frameCache;

    @Inject
    SecurityIdentity securityIdentity;

    @Inject
    TestDao testDao;

    private static final int MIN_PIN = 1337;
    private static final int MAX_PIN = 4200;

    private final Map<String, WebSocketConnection> sentinelConnections = new ConcurrentHashMap<>();
    private final Map<String, String> sentinelNames = new ConcurrentHashMap<>();
    private final Map<String, Integer> sentinelPins = new ConcurrentHashMap<>();
    private final Map<String, WebSocketConnection> proctorConnections = new ConcurrentHashMap<>();
    private final Map<String, Integer> proctorPinFilters = new ConcurrentHashMap<>();

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
                if (securityIdentity.hasRole("teacher") || securityIdentity.hasRole("admin")) {
                    handleProctorMessage(msg, connection);
                } else {
                    Log.warnf("Unauthorized proctor access attempt by: %s", securityIdentity.getPrincipal());
                    connection.close().subscribe().with(
                            success -> Log.infof("Closed unauthorized connection: %s", connection.id()),
                            failure -> Log.errorf("Failed to close connection: %s", failure.getMessage())
                    );
                }
            }
        } catch (Exception e) {
            Log.error("JSON Error: " + e.getMessage());
        }
    }

    // Processes sentinel registration and frames
    private void handleSentinelMessage(WsMessage msg, WebSocketConnection connection) throws Exception {
        switch (msg.type()) {
            case "sentinel.register":
                Integer pin = getPinFromPayload(msg.payload());
                
                if (pin == null) {
                    sendJson(connection, "server.registration.reject", new RegistrationRejectPayload("PIN is required"));
                    connection.close().subscribe();
                    break;
                }
                
                if (pin < MIN_PIN || pin > MAX_PIN) {
                    sendJson(connection, "server.registration.reject", new RegistrationRejectPayload("PIN must be between " + MIN_PIN + " and " + MAX_PIN));
                    connection.close().subscribe();
                    break;
                }
                
                if (testDao.findByPin(pin).isEmpty()) {
                    sendJson(connection, "server.registration.reject", new RegistrationRejectPayload("Invalid PIN"));
                    connection.close().subscribe();
                    break;
                }
                
                String sentinelId = UUID.randomUUID().toString();
                sentinelConnections.put(sentinelId, connection);
                sentinelPins.put(sentinelId, pin);

                JsonWebToken jwt = (JsonWebToken) securityIdentity.getPrincipal();
                String givenName = jwt.getClaim("given_name");
                String familyName = jwt.getClaim("family_name");
                String name = ((givenName != null ? givenName : "") + " " + (familyName != null ? familyName : "")).trim();
                sentinelNames.put(sentinelId, name);

                sendJson(connection, "server.registration.ack", new SentinelAckPayload(sentinelId));
                broadcastSentinelList();
                break;

            case "sentinel.frame":
                processIncomingFrames(msg);
                break;
        }
    }

    // Processes proctor registration and subscriptions
    private void handleProctorMessage(WsMessage msg, WebSocketConnection connection) throws Exception {
        String proctorId = connection.id();

        switch (msg.type()) {
            case "proctor.register":
                proctorConnections.put(proctorId, connection);
                sendJson(connection, "server.registration.ack", new RegistrationAckPayload(proctorId));
                sendCurrentSentinelList(connection);
                break;

            case "proctor.set-pin":
                Integer proctorPin = getPinFromPayload(msg.payload());
                if (proctorPin != null && proctorPin >= MIN_PIN && proctorPin <= MAX_PIN) {
                    proctorPinFilters.put(proctorId, proctorPin);
                    sendCurrentSentinelList(connection);
                }
                break;

            case "proctor.subscribe":
                String sentinelIdToSubscribe = getSentinelIdFromPayload(msg.payload());

                if (sentinelIdToSubscribe != null) {
                    Integer pinFilter = proctorPinFilters.get(proctorId);
                    Integer sentinelPin = sentinelPins.get(sentinelIdToSubscribe);
                    
                    if (pinFilter != null && !pinFilter.equals(sentinelPin)) {
                        Log.warnf("Proctor %s attempted to subscribe to sentinel %s with non-matching PIN", proctorId, sentinelIdToSubscribe);
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
                SetProfilePayload setProfilePayload = objectMapper.convertValue(msg.payload(), SetProfilePayload.class);
                String targetSentinelId = setProfilePayload.sentinelId();
                String profile = setProfilePayload.profile();

                if (targetSentinelId != null && profile != null) {
                    WebSocketConnection sentinelConnection = sentinelConnections.get(targetSentinelId);
                    if (sentinelConnection != null) {
                        int maxSidePx = profileToMaxSidePx(profile);
                        sendJson(sentinelConnection, "server.set-resolution", new SetResolutionPayload(maxSidePx));
                        Log.infof("Sent set-resolution to sentinel %s with maxSidePx=%d (profile=%s)", targetSentinelId, maxSidePx, profile);
                    } else {
                        Log.warnf("Sentinel %s not found for set-profile request", targetSentinelId);
                    }
                }
                break;
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
            connection.sendText(objectMapper.writeValueAsString(msg)).subscribe().with(
                    success -> {},
                    failure -> Log.errorf("Failed to send JSON message: %s", failure.getMessage())
            );
        } catch (Exception e) {
            Log.errorf("Failed to send JSON message: %s", e.getMessage());
        }
    }

    private List<SentinelInfo> buildSentinelInfoList() {
        return sentinelConnections.keySet().stream()
                .map(id -> new SentinelInfo(id, sentinelNames.getOrDefault(id, "")))
                .toList();
    }

    private List<SentinelInfo> buildSentinelInfoList(Integer pinFilter) {
        return sentinelConnections.entrySet().stream()
                .filter(entry -> {
                    if (pinFilter == null) return true;
                    Integer sentinelPin = sentinelPins.get(entry.getKey());
                    return pinFilter.equals(sentinelPin);
                })
                .map(entry -> new SentinelInfo(entry.getKey(), sentinelNames.getOrDefault(entry.getKey(), "")))
                .toList();
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

    private Integer getPinFromPayload(Object payload) {
        if (payload instanceof Map<?, ?> map) {
            Object pin = map.get("pin");
            if (pin instanceof Integer) {
                return (Integer) pin;
            } else if (pin instanceof Number) {
                return ((Number) pin).intValue();
            } else if (pin != null) {
                try {
                    return Integer.parseInt(pin.toString());
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
    }
}

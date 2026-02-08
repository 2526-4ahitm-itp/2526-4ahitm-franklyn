package at.ac.htlleonding.franklynserver.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.websocket.*;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;
import at.ac.htlleonding.franklynserver.model.*;
import at.ac.htlleonding.franklynserver.cache.Cache;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@ServerEndpoint("/ws/{service}")
@ApplicationScoped
public class FranklynWebSocketServer {

    private static final String SERVICE_SENTINEL = "sentinel";
    private static final String SERVICE_PROCTOR = "proctor";

    @Inject
    ObjectMapper objectMapper;

    @Inject
    Cache frameCache;

    private final Map<String, Session> sentinelSessions = new ConcurrentHashMap<>();
    private final Map<String, Session> proctorSessions = new ConcurrentHashMap<>();

    private final Map<String, Set<String>> subscriptions = new ConcurrentHashMap<>();

    @OnOpen
    public void onOpen(Session session, @PathParam("service") String service) {
        System.out.println("New connection as: " + service);
    }

    @OnMessage
    public void onMessage(String jsonMessage, Session session, @PathParam("service") String service) {
        try {
            WsMessage msg = objectMapper.readValue(jsonMessage, WsMessage.class);

            if (SERVICE_SENTINEL.equals(service)) {
                handleSentinelMessage(msg, session);
            } else if (SERVICE_PROCTOR.equals(service)) {
                handleProctorMessage(msg, session);
            }
        } catch (Exception e) {
            System.err.println("JSON Error: " + e.getMessage());
        }
    }

    private void handleSentinelMessage(WsMessage msg, Session session) throws Exception {
        switch (msg.type()) {
            case "sentinel.register":
                String sentinelId = UUID.randomUUID().toString();
                sentinelSessions.put(sentinelId, session);

                sendJson(session, "server.registration.ack", new SentinelAckPayload(sentinelId));
                broadcastSentinelList();
                break;

            case "sentinel.frame":
                processIncomingFrames(msg);
                break;
        }
    }

    private void handleProctorMessage(WsMessage msg, Session session) throws Exception {
        switch (msg.type()) {
            case "proctor.register":
                String proctorId = UUID.randomUUID().toString();
                proctorSessions.put(proctorId, session);

                sendJson(session, "server.registration.ack", new RegistrationAckPayload(proctorId));
                sendCurrentSentinelList(session);
                break;

            case "proctor.subscribe":
                String currentProctorId = getProctorIdBySession(session);
                String sentinelIdToSubscribe = getSentinelIdFromPayload(msg.payload());

                if (currentProctorId != null && sentinelIdToSubscribe != null) {
                    subscriptions.computeIfAbsent(currentProctorId, k -> new HashSet<>()).add(sentinelIdToSubscribe);
                    sendCachedFrameToProctor(session, sentinelIdToSubscribe);
                }
                break;

            case "proctor.revoke-subscription":
                String proctorIdRevoke = getProctorIdBySession(session);
                String sentinelIdToUnsubscribe = getSentinelIdFromPayload(msg.payload());

                if (proctorIdRevoke != null && subscriptions.containsKey(proctorIdRevoke)) {
                    subscriptions.get(proctorIdRevoke).remove(sentinelIdToUnsubscribe);
                }
                break;
        }
    }

    private void processIncomingFrames(WsMessage sentinelFrameMsg) {
        FramesPayload framesPayload = objectMapper.convertValue(sentinelFrameMsg.payload(), FramesPayload.class);
        for (Frame frame : framesPayload.frames()) {
            frameCache.saveFrame(frame, UUID.fromString(frame.sentinelId()));
        }
    }

    private void sendCachedFrameToProctor(Session proctorSession, String sentinelId) {
        frameCache.getFrame(UUID.fromString(sentinelId)).ifPresent(frame -> {
            sendJson(proctorSession, "server.frame", new FramesPayload(List.of(frame)));
        });
    }

    @OnClose
    public void onClose(Session session, @PathParam("service") String service) {
        sentinelSessions.entrySet().removeIf(entry -> entry.getValue().equals(session));
        proctorSessions.entrySet().removeIf(entry -> entry.getValue().equals(session));
        broadcastSentinelList();
    }


    private void sendJson(Session session, String type, Object payload) {
        try {
            WsMessage msg = new WsMessage(type, Instant.now().getEpochSecond(), payload);
            session.getAsyncRemote().sendText(objectMapper.writeValueAsString(msg));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void broadcastSentinelList() {
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(new ArrayList<>(sentinelSessions.keySet()));
        WsMessage message = new WsMessage("server.update-sentinels", Instant.now().getEpochSecond(), payload);

        try {
            String jsonMessage = objectMapper.writeValueAsString(message);
            proctorSessions.values().forEach(session -> {
                session.getAsyncRemote().sendText(jsonMessage);
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void sendCurrentSentinelList(Session proctorSession) {
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(new ArrayList<>(sentinelSessions.keySet()));
        sendJson(proctorSession, "server.update-sentinels", payload);
    }

    private String getProctorIdBySession(Session session) {
        return proctorSessions.entrySet().stream()
                .filter(entry -> entry.getValue().equals(session))
                .map(Map.Entry::getKey)
                .findFirst()
                .orElse(null);
    }

    private String getSentinelIdFromPayload(Object payload) {
        if (payload instanceof Map<?, ?> map) {
            Object sentinelId = map.get("sentinelId");
            return sentinelId != null ? sentinelId.toString() : null;
        }
        return null;
    }
}
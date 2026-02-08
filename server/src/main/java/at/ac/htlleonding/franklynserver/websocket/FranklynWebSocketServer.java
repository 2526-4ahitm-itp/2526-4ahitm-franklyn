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

@ServerEndpoint("/ws/{dienstTyp}")
@ApplicationScoped
public class FranklynWebSocketServer {

    @Inject
    ObjectMapper objectMapper;

    @Inject
    Cache frameCache;

    Map<String, Session> sentinelSessions = new ConcurrentHashMap<>();
    Map<String, Session> proctorSessions = new ConcurrentHashMap<>();

    Map<String, Set<String>> subscriptions = new ConcurrentHashMap<>();

    @OnOpen
    public void onOpen(Session session, @PathParam("dienstTyp") String dienstTyp) {
        System.out.println("Neue Verbindung als: " + dienstTyp);
    }

    @OnMessage
    public void onMessage(String jsonMessage, Session session, @PathParam("dienstTyp") String dienstTyp) {
        try {
            WsMessage msg = objectMapper.readValue(jsonMessage, WsMessage.class);

            if ("sentinel".equals(dienstTyp)) {
                handleSentinelMessage(msg, session);
            } else if ("proctor".equals(dienstTyp)) {
                handleProctorMessage(msg, session);
            }
        } catch (Exception e) {
            System.err.println("JSON Fehler: " + e.getMessage());
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
                String pIdSub = getProctorIdBySession(session);
                String sIdSub = getSentinelIdFromJson(msg.payload());
                subscriptions.computeIfAbsent(pIdSub, k -> new HashSet<>()).add(sIdSub);

                sendCachedFrameToProctor(session, sIdSub);
                break;

            case "proctor.revoke-subscription":
                String pIdRev = getProctorIdBySession(session);
                String sIdRev = getSentinelIdFromJson(msg.payload());
                if (subscriptions.containsKey(pIdRev)) {
                    subscriptions.get(pIdRev).remove(sIdRev);
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
    public void onClose(Session session, @PathParam("dienstTyp") String dienstTyp) {
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
        WsMessage msg = new WsMessage("server.update-sentinels", Instant.now().getEpochSecond(), payload);
        proctorSessions.values().forEach(s -> {
            try {
                s.getAsyncRemote().sendText(objectMapper.writeValueAsString(msg));
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    private void sendCurrentSentinelList(Session proctorSession) {
        UpdateSentinelsPayload payload = new UpdateSentinelsPayload(new ArrayList<>(sentinelSessions.keySet()));
        sendJson(proctorSession, "server.update-sentinels", payload);
    }

    private String getProctorIdBySession(Session session) {
        return proctorSessions.entrySet().stream().filter(entry -> entry.getValue().equals(session)).map(Map.Entry::getKey).findFirst().orElse(null);
    }

    private String getSentinelIdFromJson(Object payload) {
        Map<?, ?> map = (Map<?, ?>) payload;
        return (String) map.get("sentinelId");
    }
}
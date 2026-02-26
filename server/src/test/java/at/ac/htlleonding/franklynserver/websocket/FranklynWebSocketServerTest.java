package at.ac.htlleonding.franklynserver.websocket;

import at.ac.htlleonding.franklynserver.cache.Cache;
import at.ac.htlleonding.franklynserver.cache.FrameListener;
import at.ac.htlleonding.franklynserver.model.Frame;
import at.ac.htlleonding.franklynserver.model.FramesPayload;
import at.ac.htlleonding.franklynserver.model.WsMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.websocket.RemoteEndpoint;
import jakarta.websocket.Session;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.*;

class FranklynWebSocketServerTest {

    private FranklynWebSocketServer server;
    private ObjectMapper objectMapper;
    private Cache frameCache;
    private Map<String, Session> sentinelSessions;
    private Map<String, Session> proctorSessions;
    private Map<String, Set<FrameListener>> proctorListeners;

    @BeforeEach
    void setUp() throws Exception {
        server = new FranklynWebSocketServer();
        objectMapper = new ObjectMapper();
        frameCache = new Cache();

        Field objectMapperField = FranklynWebSocketServer.class.getDeclaredField("objectMapper");
        objectMapperField.setAccessible(true);
        objectMapperField.set(server, objectMapper);

        Field frameCacheField = FranklynWebSocketServer.class.getDeclaredField("frameCache");
        frameCacheField.setAccessible(true);
        frameCacheField.set(server, frameCache);

        Field sentinelSessionsField = FranklynWebSocketServer.class.getDeclaredField("sentinelSessions");
        sentinelSessionsField.setAccessible(true);
        sentinelSessions = (Map<String, Session>) sentinelSessionsField.get(server);

        Field proctorSessionsField = FranklynWebSocketServer.class.getDeclaredField("proctorSessions");
        proctorSessionsField.setAccessible(true);
        proctorSessions = (Map<String, Session>) proctorSessionsField.get(server);

        Field proctorListenersField = FranklynWebSocketServer.class.getDeclaredField("proctorListeners");
        proctorListenersField.setAccessible(true);
        proctorListeners = (Map<String, Set<FrameListener>>) proctorListenersField.get(server);
    }

    @Test
    void onOpen_acceptsProctorService() {
        Session mockSession = createMockSession();

        assertThatCode(() -> server.onOpen(mockSession, "proctor")).doesNotThrowAnyException();
    }

    @Test
    void onMessage_sentinelRegister_addsSentinelSession() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("sentinel.register", System.currentTimeMillis(), null);
        String jsonMessage = objectMapper.writeValueAsString(registerMsg);

        server.onMessage(jsonMessage, mockSession, "sentinel");

        assertThat(sentinelSessions).hasSize(1);
        assertThat(sentinelSessions.values()).contains(mockSession);
    }

    @Test
    void onMessage_sentinelRegister_sendsAck() throws Exception {
        AtomicReference<String> sentMessage = new AtomicReference<>();
        Session mockSession = createMockSessionWithCapture(sentMessage);
        WsMessage registerMsg = new WsMessage("sentinel.register", System.currentTimeMillis(), null);
        String jsonMessage = objectMapper.writeValueAsString(registerMsg);

        server.onMessage(jsonMessage, mockSession, "sentinel");

        assertThat(sentMessage.get()).isNotNull();
        assertThat(sentMessage.get()).contains("server.registration.ack");
        assertThat(sentMessage.get()).contains("sentinelId");
    }

    @Test
    void onMessage_proctorRegister_addsProctorSession() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        String jsonMessage = objectMapper.writeValueAsString(registerMsg);

        server.onMessage(jsonMessage, mockSession, "proctor");

        assertThat(proctorSessions).hasSize(1);
        assertThat(proctorSessions.values()).contains(mockSession);
    }

    @Test
    void onMessage_proctorRegister_sendsAckAndSentinelList() throws Exception {
        AtomicReference<String> sentMessage = new AtomicReference<>();
        Session mockSession = createMockSessionWithCapture(sentMessage);
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        String jsonMessage = objectMapper.writeValueAsString(registerMsg);

        server.onMessage(jsonMessage, mockSession, "proctor");

        assertThat(sentMessage.get()).isNotNull();
    }

    @Test
    void onMessage_sentinelFrame_savesFrameToCache() throws Exception {
        Session mockSession = createMockSession();
        UUID sentinelId = UUID.randomUUID();
        Frame frame = new Frame(sentinelId.toString(), "frame-1", 1, "data");
        FramesPayload framesPayload = new FramesPayload(List.of(frame));
        WsMessage frameMsg = new WsMessage("sentinel.frame", System.currentTimeMillis(), framesPayload);
        String jsonMessage = objectMapper.writeValueAsString(frameMsg);

        server.onMessage(jsonMessage, mockSession, "sentinel");

        assertThat(frameCache.getFrame(sentinelId)).isPresent();
        assertThat(frameCache.getFrame(sentinelId).get().frameId()).isEqualTo("frame-1");
    }

    @Test
    void onMessage_proctorSubscribe_registersListener() throws Exception {
        // First register a proctor
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        String proctorId = proctorSessions.keySet().iterator().next();
        UUID sentinelId = UUID.randomUUID();

        // Subscribe to a sentinel
        Map<String, String> payload = new HashMap<>();
        payload.put("sentinelId", sentinelId.toString());
        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg), mockSession, "proctor");

        assertThat(proctorListeners).containsKey(proctorId);
        assertThat(proctorListeners.get(proctorId)).hasSize(1);
    }

    @Test
    void onMessage_proctorSubscribe_sendsCachedFrame() throws Exception {
        // Save a frame to cache first
        UUID sentinelId = UUID.randomUUID();
        Frame frame = new Frame(sentinelId.toString(), "cached-frame", 1, "cached-data");
        frameCache.saveFrame(frame, sentinelId);

        // Register a proctor
        AtomicReference<String> lastSentMessage = new AtomicReference<>();
        Session mockSession = createMockSessionWithCapture(lastSentMessage);
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        // Subscribe to the sentinel
        Map<String, String> payload = new HashMap<>();
        payload.put("sentinelId", sentinelId.toString());
        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg), mockSession, "proctor");

        // Verify cached frame was sent
        assertThat(lastSentMessage.get()).contains("server.frame");
        assertThat(lastSentMessage.get()).contains("cached-frame");
    }

    @Test
    void onMessage_proctorRevokeSubscription_unregistersListener() throws Exception {
        // First register a proctor
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        UUID sentinelId = UUID.randomUUID();

        // Subscribe to a sentinel
        Map<String, String> subscribePayload = new HashMap<>();
        subscribePayload.put("sentinelId", sentinelId.toString());
        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), subscribePayload);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg), mockSession, "proctor");

        String proctorId = proctorSessions.keySet().iterator().next();
        assertThat(proctorListeners.get(proctorId)).hasSize(1);

        // Revoke subscription
        Map<String, String> revokePayload = new HashMap<>();
        revokePayload.put("sentinelId", sentinelId.toString());
        WsMessage revokeMsg = new WsMessage("proctor.revoke-subscription", System.currentTimeMillis(), revokePayload);
        server.onMessage(objectMapper.writeValueAsString(revokeMsg), mockSession, "proctor");

        assertThat(proctorListeners.get(proctorId)).isEmpty();
    }

    @Test
    void onMessage_invalidJson_doesNotThrow() {
        Session mockSession = createMockSession();

        assertThatCode(() -> server.onMessage("invalid json", mockSession, "sentinel")).doesNotThrowAnyException();
    }

    @Test
    void onClose_removesProctorSession() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        assertThat(proctorSessions).hasSize(1);

        server.onClose(mockSession, "proctor");

        assertThat(proctorSessions).isEmpty();
    }

    @Test
    void onClose_unregistersProctorListeners() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        UUID sentinelId = UUID.randomUUID();
        Map<String, String> payload = new HashMap<>();
        payload.put("sentinelId", sentinelId.toString());
        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg), mockSession, "proctor");

        server.onClose(mockSession, "proctor");

        assertThat(proctorListeners).isEmpty();
    }

    @Test
    void onClose_removesSentinelSession() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("sentinel.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "sentinel");

        assertThat(sentinelSessions).hasSize(1);

        server.onClose(mockSession, "sentinel");

        assertThat(sentinelSessions).isEmpty();
    }

    @Test
    void onClose_broadcastsUpdatedSentinelList() throws Exception {
        // Register a sentinel
        Session sentinelSession = createMockSession();
        WsMessage sentinelRegisterMsg = new WsMessage("sentinel.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(sentinelRegisterMsg), sentinelSession, "sentinel");

        // Register a proctor
        AtomicReference<String> lastSentMessage = new AtomicReference<>();
        Session proctorSession = createMockSessionWithCapture(lastSentMessage);
        WsMessage proctorRegisterMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(proctorRegisterMsg), proctorSession, "proctor");

        // Close sentinel session
        server.onClose(sentinelSession, "sentinel");

        // Proctor should receive update with empty sentinel list
        assertThat(lastSentMessage.get()).contains("server.update-sentinels");
    }

    @Test
    void proctor_canSubscribeToMultipleSentinels() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        UUID sentinelId1 = UUID.randomUUID();
        UUID sentinelId2 = UUID.randomUUID();

        Map<String, String> payload1 = new HashMap<>();
        payload1.put("sentinelId", sentinelId1.toString());
        WsMessage subscribeMsg1 = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload1);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg1), mockSession, "proctor");

        Map<String, String> payload2 = new HashMap<>();
        payload2.put("sentinelId", sentinelId2.toString());
        WsMessage subscribeMsg2 = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload2);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg2), mockSession, "proctor");

        String proctorId = proctorSessions.keySet().iterator().next();
        assertThat(proctorListeners.get(proctorId)).hasSize(2);
    }

    @Test
    void frameListener_receivesNewFrames() throws Exception {
        // Register a proctor
        AtomicReference<String> lastSentMessage = new AtomicReference<>();
        Session proctorSession = createMockSessionWithCapture(lastSentMessage);
        WsMessage proctorRegisterMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(proctorRegisterMsg), proctorSession, "proctor");

        UUID sentinelId = UUID.randomUUID();

        // Subscribe proctor to sentinel
        Map<String, String> payload = new HashMap<>();
        payload.put("sentinelId", sentinelId.toString());
        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload);
        server.onMessage(objectMapper.writeValueAsString(subscribeMsg), proctorSession, "proctor");

        // Send a frame from sentinel
        Session sentinelSession = createMockSession();
        Frame frame = new Frame(sentinelId.toString(), "new-frame", 1, "new-data");
        FramesPayload framesPayload = new FramesPayload(List.of(frame));
        WsMessage frameMsg = new WsMessage("sentinel.frame", System.currentTimeMillis(), framesPayload);
        server.onMessage(objectMapper.writeValueAsString(frameMsg), sentinelSession, "sentinel");

        // Proctor should receive the new frame
        assertThat(lastSentMessage.get()).contains("server.frame");
        assertThat(lastSentMessage.get()).contains("new-frame");
    }

    @Test
    void onMessage_proctorSubscribe_withoutRegistration_doesNotFail() {
        Session mockSession = createMockSession();
        UUID sentinelId = UUID.randomUUID();

        Map<String, String> payload = new HashMap<>();
        payload.put("sentinelId", sentinelId.toString());
        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), payload);

        assertThatCode(() -> server.onMessage(objectMapper.writeValueAsString(subscribeMsg), mockSession, "proctor")).doesNotThrowAnyException();
    }

    @Test
    void onMessage_proctorSubscribe_withNullPayload_doesNotFail() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        WsMessage subscribeMsg = new WsMessage("proctor.subscribe", System.currentTimeMillis(), null);

        assertThatCode(() -> server.onMessage(objectMapper.writeValueAsString(subscribeMsg), mockSession, "proctor")).doesNotThrowAnyException();
    }

    @Test
    void onMessage_proctorRevokeSubscription_withoutSubscription_doesNotFail() throws Exception {
        Session mockSession = createMockSession();
        WsMessage registerMsg = new WsMessage("proctor.register", System.currentTimeMillis(), null);
        server.onMessage(objectMapper.writeValueAsString(registerMsg), mockSession, "proctor");

        UUID sentinelId = UUID.randomUUID();
        Map<String, String> payload = new HashMap<>();
        payload.put("sentinelId", sentinelId.toString());
        WsMessage revokeMsg = new WsMessage("proctor.revoke-subscription", System.currentTimeMillis(), payload);

        assertThatCode(() -> server.onMessage(objectMapper.writeValueAsString(revokeMsg), mockSession, "proctor")).doesNotThrowAnyException();
    }

    @Test
    void onClose_withNonExistentSession_doesNotFail() {
        Session mockSession = createMockSession();

        assertThatCode(() -> server.onClose(mockSession, "proctor")).doesNotThrowAnyException();
    }

    private Session createMockSession() {
        Session session = mock(Session.class);
        RemoteEndpoint.Async asyncRemote = mock(RemoteEndpoint.Async.class);
        
        when(session.getId()).thenReturn(UUID.randomUUID().toString());
        when(session.isOpen()).thenReturn(true);
        when(session.getAsyncRemote()).thenReturn(asyncRemote);
        when(asyncRemote.sendText(anyString())).thenReturn(CompletableFuture.completedFuture(null));
        
        return session;
    }

    private Session createMockSessionWithCapture(AtomicReference<String> capture) {
        Session session = mock(Session.class);
        RemoteEndpoint.Async asyncRemote = mock(RemoteEndpoint.Async.class);
        
        when(session.getId()).thenReturn(UUID.randomUUID().toString());
        when(session.isOpen()).thenReturn(true);
        when(session.getAsyncRemote()).thenReturn(asyncRemote);
        when(asyncRemote.sendText(anyString())).thenAnswer(invocation -> {
            capture.set(invocation.getArgument(0));
            return CompletableFuture.completedFuture(null);
        });
        
        return session;
    }
}

package at.ac.htlleonding.franklynserver.cache;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.context.spi.Context;
import jakarta.inject.Inject;

import java.net.http.WebSocket;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class Cache {
    @Inject
    KeepFrame keepFrame;

    final int FRAME_DURATION = keepFrame.frame_duration();
    Map<UUID, String> frameMap = new HashMap<>();
    Map<UUID, FrameListener> frameListenerMap = new HashMap<>();
    public static void main(String[] args) {

    }

    // When the Frame class is implemented use Frame frame instead of String jsonFrame

    /**
     *
     * @param jsonFrame
     * @param sentinelId
     * The saveFrame method gets a frame and the UUID of the sentinel that sent it. It saves the frame in the frameMap
     * e.g. saveFrame(frame, sentinel1.UUID);
     * would store a frame and connect it to its sentinel client. If a new frame by the same client comes in, the old
     * frame is deleted
     */
    public synchronized void saveFrame(String jsonFrame, UUID sentinelId) {
        if (frameMap.containsKey(sentinelId)) {
            frameMap.replace(sentinelId, jsonFrame);
        } else {
            frameMap.put(sentinelId, jsonFrame);
        }
        if (frameListenerMap.containsKey(sentinelId)) {
            frameListenerMap.get(sentinelId).frameConsumer.accept(jsonFrame);
        }
    }
    public Optional<String> returnFrame(UUID sentinelId) {
        return Optional.of(frameMap.get(sentinelId));
    }
    public void registerOnFrame(FrameListener frameListener) {
        frameListenerMap.put(frameListener.sentinelId, frameListener);
    }
    public void unregisterOnFrame(FrameListener frameListener) {
        frameListenerMap.remove(frameListener.sentinelId);
    }
}
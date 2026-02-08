package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.Frame;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class Cache {

    @ConfigProperty(name = "franklyn.frame-duration")
    int frameDuration;

    Map<UUID, Frame> frameMap = new HashMap<>();
    Map<UUID, FrameListener> frameListenerMap = new HashMap<>();

    // When the Frame class is implemented use Frame frame instead of String jsonFrame

    /**
     * @param frame
     * @param sentinelId The saveFrame method gets a frame and the UUID of the sentinel that sent it. It saves the frame in the frameMap
     *                   e.g. saveFrame(frame, sentinel1.UUID);
     *                   would store a frame and connect it to its sentinel client. If a new frame by the same client comes in, the old
     *                   frame is deleted
     */
    public synchronized void saveFrame(Frame frame, UUID sentinelId) {
        if (frameMap.containsKey(sentinelId)) {
            frameMap.replace(sentinelId, frame);
        } else {
            frameMap.put(sentinelId, frame);
        }
        if (frameListenerMap.containsKey(sentinelId)) {
            frameListenerMap.get(sentinelId).frameConsumer().accept(frame);
        }
    }

    public Optional<Frame> getFrame(UUID sentinelId) {
        return Optional.ofNullable(frameMap.get(sentinelId));
    }

    public void registerOnFrame(FrameListener frameListener) {
        frameListenerMap.put(frameListener.sentinelId(), frameListener);
    }

    public void unregisterOnFrame(FrameListener frameListener) {
        frameListenerMap.remove(frameListener.sentinelId());
    }
}
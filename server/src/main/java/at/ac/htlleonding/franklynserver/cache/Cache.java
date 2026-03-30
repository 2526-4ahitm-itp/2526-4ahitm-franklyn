package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.model.Frame;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class Cache {

    int frameDuration;

    Map<UUID, Frame> frameMap = new ConcurrentHashMap<>();
    Map<UUID, Set<FrameListener>> frameListeners = new ConcurrentHashMap<>();

    // When the Frame class is implemented use Frame frame instead of String jsonFrame

    /**
     * @param frame
     * @param sentinelId
     *            The saveFrame method gets a frame and the UUID of the sentinel that sent it. It saves the frame in the
     *            frameMap e.g. saveFrame(frame, sentinel1.UUID); would store a frame and connect it to its sentinel
     *            client. If a new frame by the same client comes in, the old frame is deleted
     */
    public void saveFrame(Frame frame, UUID sentinelId) {
        frameMap.put(sentinelId, frame);

        Set<FrameListener> listeners = frameListeners.get(sentinelId);
        if (listeners != null) {
            listeners.forEach(listener -> listener.frameConsumer().accept(frame));
        }
    }

    public Optional<Frame> getFrame(UUID sentinelId) {
        return Optional.ofNullable(frameMap.get(sentinelId));
    }

    public void registerOnFrame(FrameListener frameListener) {
        frameListeners.computeIfAbsent(frameListener.sentinelId(), k -> ConcurrentHashMap.newKeySet())
                .add(frameListener);
    }

    public void unregisterOnFrame(FrameListener frameListener) {
        Set<FrameListener> listeners = frameListeners.get(frameListener.sentinelId());
        if (listeners != null) {
            listeners.remove(frameListener);
        }
    }
}

package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.model.Frame;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class FrameStore {

    private final Map<UUID, List<byte[]>> frames = new ConcurrentHashMap<>();

    public void store(UUID sentinelId, Frame frame) {
        byte[] jpeg = Base64.getDecoder().decode(frame.data());
        frames.computeIfAbsent(sentinelId, k -> Collections.synchronizedList(new ArrayList<>())).add(jpeg);
    }

    public List<byte[]> getFrames(UUID sentinelId) {
        List<byte[]> stored = frames.get(sentinelId);
        return stored != null ? List.copyOf(stored) : Collections.emptyList();
    }
}

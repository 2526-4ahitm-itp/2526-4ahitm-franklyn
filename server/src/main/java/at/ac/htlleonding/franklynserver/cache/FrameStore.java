package at.ac.htlleonding.franklynserver.cache;

import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.model.Frame;
import org.jboss.logging.Logger;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;

@ApplicationScoped
public class FrameStore {

    private static final Logger LOG = Logger.getLogger(FrameStore.class);

    @Inject
    FranklynConfig config;

    private final ConcurrentHashMap<UUID, AtomicInteger> counters = new ConcurrentHashMap<>();

    public void store(UUID sentinelId, Frame frame) {
        byte[] jpeg = Base64.getDecoder().decode(frame.data());
        Path dir = framesDir(sentinelId);
        try {
            Files.createDirectories(dir);
            int idx = counters.computeIfAbsent(sentinelId, k -> initCounter(framesDir(k))).getAndIncrement();
            Files.write(dir.resolve(String.format("frame%05d.jpg", idx)), jpeg);
        } catch (IOException e) {
            LOG.errorf("Failed to write frame for sentinel %s: %s", sentinelId, e.getMessage());
        }
    }

    public boolean hasFrames(UUID sentinelId) {
        Path dir = framesDir(sentinelId);
        if (!Files.exists(dir)) return false;
        try (Stream<Path> files = Files.list(dir)) {
            return files.anyMatch(p -> p.getFileName().toString().endsWith(".jpg"));
        } catch (IOException e) {
            return false;
        }
    }

    public Path framesDir(UUID sentinelId) {
        return Path.of(config.video().storageDir()).resolve("frames").resolve(sentinelId.toString());
    }

    public void migrateFrames(UUID oldSentinelId, UUID newSentinelId) {
        Path oldDir = framesDir(oldSentinelId);
        if (!Files.exists(oldDir)) return;
        Path newDir = framesDir(newSentinelId);
        try {
            Files.createDirectories(newDir);
            AtomicInteger counter = counters.computeIfAbsent(newSentinelId, k -> initCounter(framesDir(k)));
            List<Path> oldFrames;
            try (Stream<Path> s = Files.list(oldDir)) {
                oldFrames = s.filter(p -> p.getFileName().toString().endsWith(".jpg"))
                        .sorted()
                        .toList();
            }
            for (Path f : oldFrames) {
                int idx = counter.getAndIncrement();
                Files.move(f, newDir.resolve(String.format("frame%05d.jpg", idx)));
            }
            Files.deleteIfExists(oldDir);
            counters.remove(oldSentinelId);
            LOG.infof("Migrated %d frames from sentinel %s to %s", oldFrames.size(), oldSentinelId, newSentinelId);
        } catch (IOException e) {
            LOG.errorf("Failed to migrate frames %s → %s: %s", oldSentinelId, newSentinelId, e.getMessage());
        }
    }

    private AtomicInteger initCounter(Path dir) {
        if (!Files.exists(dir)) return new AtomicInteger(0);
        try (Stream<Path> files = Files.list(dir)) {
            int count = (int) files.filter(p -> p.getFileName().toString().endsWith(".jpg")).count();
            return new AtomicInteger(count);
        } catch (IOException e) {
            return new AtomicInteger(0);
        }
    }
}

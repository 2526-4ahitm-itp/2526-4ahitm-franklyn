package at.ac.htlleonding.franklynserver.service;

import at.ac.htlleonding.franklynserver.cache.FrameStore;
import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import io.quarkus.logging.Log;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Stream;

/**
 * Deletes recorded frames and generated videos once the retention window after their exam's end has elapsed.
 */
@ApplicationScoped
public class VideoRetentionService {

    @Inject
    FrameStore frameStore;

    @Inject
    ExamSessionDao examSessionDao;

    @Inject
    FranklynConfig config;

    @Scheduled(cron = "0 0 3 * * ?", timeZone = "Europe/Vienna",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void purgeExpired() {
        Instant cutoff = Instant.now().minus(Duration.ofDays(config.video().retentionDays()));
        Log.infof("[retention] purging frames and videos of exams ended before %s", cutoff);
        purgeVideos(cutoff);
        purgeFrames(cutoff);
    }

    private void purgeVideos(Instant cutoff) {
        for (ExamSession session : examSessionDao.findWithVideoEndedBefore(cutoff)) {
            try {
                Files.deleteIfExists(Path.of(session.videoFilePath()));
                // FAILED rather than null: the frames are gone too, so the video cannot be regenerated
                examSessionDao.updateVideo(session.sentinelId(), "FAILED", null);
                Log.infof("[retention] deleted video sentinel=%s", session.sentinelId());
            } catch (IOException e) {
                Log.errorf(e, "[retention] failed to delete video sentinel=%s", session.sentinelId());
            }
        }
    }

    private void purgeFrames(Instant cutoff) {
        Path root = frameStore.framesRoot();
        if (!Files.isDirectory(root)) {
            return;
        }

        List<Path> dirs;
        try (Stream<Path> entries = Files.list(root)) {
            dirs = entries.filter(Files::isDirectory).toList();
        } catch (IOException e) {
            Log.errorf(e, "[retention] failed to list frame directories in %s", root);
            return;
        }

        Map<UUID, Instant> examEnds = examSessionDao.findExamEndsBySentinelId();
        for (Path dir : dirs) {
            UUID sentinelId;
            try {
                sentinelId = UUID.fromString(dir.getFileName().toString());
            } catch (IllegalArgumentException e) {
                continue;
            }

            try {
                // Frames without a session (e.g. its insert failed) fall back to the time of the last written frame
                Instant examEnd = examEnds.get(sentinelId);
                Instant reference = examEnd != null ? examEnd : Files.getLastModifiedTime(dir).toInstant();
                if (reference.isBefore(cutoff)) {
                    frameStore.deleteFrames(sentinelId);
                    Log.infof("[retention] deleted frames sentinel=%s", sentinelId);
                }
            } catch (IOException e) {
                Log.errorf(e, "[retention] failed to delete frames sentinel=%s", sentinelId);
            }
        }
    }
}

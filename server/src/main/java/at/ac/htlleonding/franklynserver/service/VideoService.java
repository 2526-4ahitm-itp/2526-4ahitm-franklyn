package at.ac.htlleonding.franklynserver.service;

import at.ac.htlleonding.franklynserver.cache.FrameStore;
import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.repository.exam.ExamDao;
import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import io.quarkus.logging.Log;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import org.eclipse.microprofile.context.ManagedExecutor;

@ApplicationScoped
public class VideoService {

    @Inject
    FrameStore frameStore;

    @Inject
    ExamSessionDao examSessionDao;

    @Inject
    UserDao userDao;

    @Inject
    ExamDao examDao;

    @Inject
    FranklynConfig config;

    @Inject
    ManagedExecutor managedExecutor;

    private String buildFilename(ExamSession session, UUID sentinelId) {
        if (session == null) {
            return sentinelId.toString();
        }
        User user = userDao.findById(session.studentId()).orElse(null);
        Exam exam = examDao.findById(session.examId()).orElse(null);

        String lastName = user != null && user.familyName() != null ? user.familyName() : "unknown";
        String firstName = user != null && user.givenName() != null ? user.givenName() : "unknown";
        String examTitle = exam != null ? exam.title() : "unknown";

        return sanitize(lastName + "_" + firstName + "_" + examTitle);
    }

    private String sanitize(String name) {
        return name.replaceAll("[^a-zA-Z0-9_\\-]", "_");
    }

    private synchronized Path resolveUniqueOutputPath(Path storageDir, String baseName) {
        Path candidate = storageDir.resolve(baseName + ".mp4");
        if (!Files.exists(candidate)) {
            return candidate;
        }
        int i = 1;
        while (Files.exists(candidate)) {
            candidate = storageDir.resolve(baseName + "_" + i + ".mp4");
            i++;
        }
        return candidate;
    }

    public void scheduleVideoGeneration(UUID sentinelId) {
        examSessionDao.setPendingStatus(sentinelId);
        CompletableFuture.runAsync(() -> generateVideo(sentinelId), managedExecutor)
                .exceptionally(e -> {
                    Log.errorf(e, "Unhandled exception escaping generateVideo for sentinel %s", sentinelId);
                    try {
                        examSessionDao.updateVideo(sentinelId, "FAILED", null);
                    } catch (Exception dbEx) {
                        Log.errorf(dbEx, "Failed to set FAILED status in exceptionally handler for %s", sentinelId);
                    }
                    return null;
                });
    }

    private void generateVideo(UUID sentinelId) {
        Log.debugf("[video] generateVideo start sentinel=%s thread=%s", sentinelId, Thread.currentThread().getName());

        if (!frameStore.hasFrames(sentinelId)) {
            Log.warnf("[video] no frames for sentinel=%s, marking FAILED", sentinelId);
            examSessionDao.updateVideo(sentinelId, "FAILED", null);
            return;
        }

        try {
            Path framesDir = frameStore.framesDir(sentinelId);
            Path storageDir = Path.of(config.video().storageDir());
            Files.createDirectories(storageDir);

            ExamSession session = examSessionDao.findBySentinelId(sentinelId).orElse(null);
            String filename = buildFilename(session, sentinelId);
            Path outputPath = resolveUniqueOutputPath(storageDir, filename);
            Log.debugf("[video] sentinel=%s outputPath=%s", sentinelId, outputPath);

            Process process = new ProcessBuilder(
                    "ffmpeg",
                    "-framerate", "2",
                    "-i", framesDir.resolve("frame%05d.jpg").toString(),
                    "-c:v", "libx264",
                    "-pix_fmt", "yuv420p",
                    outputPath.toString())
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .redirectError(ProcessBuilder.Redirect.DISCARD)
                    .start();

            int exitCode = process.waitFor();
            Log.debugf("[video] sentinel=%s ffmpeg exit=%d", sentinelId, exitCode);
            if (exitCode != 0) {
                Log.errorf("[video] ffmpeg exit=%d sentinel=%s", exitCode, sentinelId);
                examSessionDao.updateVideo(sentinelId, "FAILED", null);
                return;
            }

            Log.debugf("[video] sentinel=%s calling updateVideo DONE path=%s", sentinelId, outputPath);
            examSessionDao.updateVideo(sentinelId, "DONE", outputPath.toString());
            Log.infof("[video] generation complete sentinel=%s", sentinelId);
        } catch (IOException | InterruptedException e) {
            Log.errorf(e, "[video] generation failed sentinel=%s", sentinelId);
            try {
                examSessionDao.updateVideo(sentinelId, "FAILED", null);
            } catch (Exception dbEx) {
                Log.errorf(dbEx, "[video] also failed to set FAILED status sentinel=%s", sentinelId);
            }
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
        }
    }
}

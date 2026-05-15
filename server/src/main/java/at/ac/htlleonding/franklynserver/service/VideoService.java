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
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

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

    public void scheduleVideoGeneration(UUID sentinelId) {
        examSessionDao.setPendingStatus(sentinelId);
        CompletableFuture.runAsync(() -> generateVideo(sentinelId));
    }

    private void generateVideo(UUID sentinelId) {
        List<byte[]> jpegFrames = frameStore.getFrames(sentinelId);
        if (jpegFrames.isEmpty()) {
            Log.warnf("No frames stored for sentinel %s, skipping video generation", sentinelId);
            return;
        }

        Path tempDir = null;
        try {
            Path storageDir = Path.of(config.video().storageDir());
            Files.createDirectories(storageDir);

            tempDir = Files.createTempDirectory("franklyn-video-");

            for (int i = 0; i < jpegFrames.size(); i++) {
                Path framePath = tempDir.resolve(String.format("frame%05d.jpg", i));
                Files.write(framePath, jpegFrames.get(i));
            }

            ExamSession session = examSessionDao.findBySentinelId(sentinelId).orElse(null);
            String filename = buildFilename(session, sentinelId);
            Path outputPath = storageDir.resolve(filename + ".mp4");

            Process process = new ProcessBuilder(
                    "ffmpeg", "-y",
                    "-framerate", "2",
                    "-i", tempDir.resolve("frame%05d.jpg").toString(),
                    "-c:v", "libx264",
                    "-pix_fmt", "yuv420p",
                    outputPath.toString())
                    .redirectErrorStream(true)
                    .start();

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                Log.errorf("ffmpeg exited with code %d for sentinel %s", exitCode, sentinelId);
                return;
            }

            examSessionDao.updateVideo(sentinelId, "DONE", outputPath.toString());
            Log.infof("Video generation complete for sentinel %s", sentinelId);
        } catch (IOException | InterruptedException e) {
            Log.errorf("Video generation failed for sentinel %s: %s", sentinelId, e.getMessage());
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
        } finally {
            if (tempDir != null) {
                try {
                    Files.walk(tempDir)
                            .sorted(Comparator.reverseOrder())
                            .forEach(p -> {
                                try {
                                    Files.delete(p);
                                } catch (IOException ignored) {
                                }
                            });
                } catch (IOException ignored) {
                }
            }
        }
    }
}

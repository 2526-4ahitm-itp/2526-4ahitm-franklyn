package at.ac.htlleonding.franklynserver.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Comparator;
import java.util.UUID;
import java.util.stream.Stream;

import at.ac.htlleonding.franklynserver.cache.FrameStore;
import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.model.Frame;
import at.ac.htlleonding.franklynserver.repository.exam.ExamDao;
import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.StudentDetails;
import at.ac.htlleonding.franklynserver.repository.user.model.TeacherDetails;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.repository.user.model.UserTheme;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.jdbi.v3.core.Jdbi;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class VideoRetentionServiceTest {

    @Inject
    Jdbi jdbi;

    @Inject
    VideoRetentionService retentionService;

    @Inject
    FrameStore frameStore;

    @Inject
    ExamDao examDao;

    @Inject
    ExamSessionDao examSessionDao;

    @Inject
    UserDao userDao;

    @Inject
    FranklynConfig config;

    private UUID teacherId;
    private UUID studentId;
    private int nextPin;

    @BeforeEach
    void setUp() throws IOException {
        cleanUp();
        teacherId = UUID.randomUUID();
        studentId = UUID.randomUUID();
        userDao.insertDetailedUser(new User(teacherId, "retention-teacher", "teacher@test.com", null, null, "de",
                UserTheme.SYSTEM, UserRole.TEACHER, new TeacherDetails(teacherId)));
        userDao.insertDetailedUser(new User(studentId, "retention-student", "student@test.com", null, null, "de",
                UserTheme.SYSTEM, UserRole.STUDENT, new StudentDetails(studentId)));
        nextPin = config.pin().min();
    }

    @AfterEach
    void cleanUp() throws IOException {
        jdbi.withHandle(handle -> {
            handle.execute("DELETE FROM fr_exam_sessions");
            handle.execute("DELETE FROM fr_notice");
            handle.execute("DELETE FROM fr_exam");
            handle.execute("DELETE FROM fr_student");
            handle.execute("DELETE FROM fr_teacher");
            handle.execute("DELETE FROM fr_user");
            return null;
        });
        Path storageDir = Path.of(config.video().storageDir());
        if (Files.exists(storageDir)) {
            try (Stream<Path> paths = Files.walk(storageDir)) {
                for (Path p : paths.sorted(Comparator.reverseOrder()).toList()) {
                    Files.delete(p);
                }
            }
        }
    }

    @Test
    void purgeExpired_examEndedBeforeRetention_deletesFramesAndVideo() throws IOException {
        UUID sentinelId = recordSession(daysAgo(config.video().retentionDays() + 1), true);
        Path video = Path.of(session(sentinelId).videoFilePath());

        retentionService.purgeExpired();

        assertThat(frameStore.framesDir(sentinelId)).doesNotExist();
        assertThat(video).doesNotExist();
        assertThat(session(sentinelId).videoFilePath()).isNull();
        assertThat(session(sentinelId).videoStatus()).isEqualTo("FAILED");
    }

    @Test
    void purgeExpired_examEndedWithinRetention_keepsFramesAndVideo() throws IOException {
        UUID sentinelId = recordSession(daysAgo(config.video().retentionDays() - 1), true);
        Path video = Path.of(session(sentinelId).videoFilePath());

        retentionService.purgeExpired();

        assertThat(frameStore.hasFrames(sentinelId)).isTrue();
        assertThat(video).exists();
        assertThat(session(sentinelId).videoStatus()).isEqualTo("DONE");
    }

    @Test
    void purgeExpired_examNeverEnded_usesScheduledEndTime() throws IOException {
        UUID sentinelId = recordSession(daysAgo(config.video().retentionDays() + 1), false);
        Path video = Path.of(session(sentinelId).videoFilePath());

        retentionService.purgeExpired();

        assertThat(frameStore.framesDir(sentinelId)).doesNotExist();
        assertThat(video).doesNotExist();
    }

    @Test
    void purgeExpired_examRunningPastStaleScheduledEnd_keepsFramesAndVideo() throws IOException {
        UUID sentinelId = recordSession(daysAgo(config.video().retentionDays() + 1), Instant.now(), null);
        Path video = Path.of(session(sentinelId).videoFilePath());

        retentionService.purgeExpired();

        assertThat(frameStore.hasFrames(sentinelId)).isTrue();
        assertThat(video).exists();
        assertThat(session(sentinelId).videoStatus()).isEqualTo("DONE");
    }

    @Test
    void purgeExpired_examStartedBeforeRetentionAndNeverEnded_deletesFramesAndVideo() throws IOException {
        UUID sentinelId = recordSession(daysAgo(config.video().retentionDays() + 10),
                daysAgo(config.video().retentionDays() + 1), null);
        Path video = Path.of(session(sentinelId).videoFilePath());

        retentionService.purgeExpired();

        assertThat(frameStore.framesDir(sentinelId)).doesNotExist();
        assertThat(video).doesNotExist();
    }

    @Test
    void purgeExpired_framesWithoutSession_useLastWriteTime() throws IOException {
        UUID oldOrphan = UUID.randomUUID();
        UUID recentOrphan = UUID.randomUUID();
        storeFrame(oldOrphan);
        storeFrame(recentOrphan);
        Files.setLastModifiedTime(frameStore.framesDir(oldOrphan),
                FileTime.from(daysAgo(config.video().retentionDays() + 1)));

        retentionService.purgeExpired();

        assertThat(frameStore.framesDir(oldOrphan)).doesNotExist();
        assertThat(frameStore.hasFrames(recentOrphan)).isTrue();
    }

    private UUID recordSession(Instant examEnd, boolean ended) throws IOException {
        Instant examStart = examEnd.minus(Duration.ofHours(2));
        return ended ? recordSession(examEnd, examStart, examEnd) : recordSession(examEnd, null, null);
    }

    private UUID recordSession(Instant scheduledEnd, Instant startedAt, Instant endedAt) throws IOException {
        Instant scheduledStart = scheduledEnd.minus(Duration.ofHours(2));
        Exam exam = examDao.insert(teacherId, "Retention exam", scheduledStart, scheduledEnd, nextPin++);
        if (startedAt != null) {
            examDao.update(exam.id(), exam.title(), teacherId, scheduledStart, scheduledEnd, startedAt, endedAt);
        }

        UUID sentinelId = UUID.randomUUID();
        examSessionDao.insert(studentId, sentinelId, exam.id());
        storeFrame(sentinelId);

        Path video = Path.of(config.video().storageDir()).resolve(sentinelId + ".mp4");
        Files.write(video, new byte[] {0});
        examSessionDao.updateVideo(sentinelId, "DONE", video.toString());
        return sentinelId;
    }

    private void storeFrame(UUID sentinelId) {
        String data = Base64.getEncoder().encodeToString(new byte[] {1, 2, 3});
        frameStore.store(sentinelId, new Frame(sentinelId.toString(), "frame", 0, data));
    }

    private ExamSession session(UUID sentinelId) {
        return examSessionDao.findBySentinelId(sentinelId).orElseThrow();
    }

    private static Instant daysAgo(int days) {
        return Instant.now().minus(Duration.ofDays(days));
    }
}

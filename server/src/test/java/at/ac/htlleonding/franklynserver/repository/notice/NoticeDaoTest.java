package at.ac.htlleonding.franklynserver.repository.notice;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import org.jdbi.v3.core.Jdbi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;

@QuarkusTest
class NoticeDaoTest {

    @Inject
    Jdbi jdbi;

    @Inject
    NoticeDao noticeDao;

    @BeforeEach
    void cleanDatabase() {
        jdbi.withHandle(handle -> handle.execute("DELETE FROM fr_notice"));
    }

    @Test
    void insert_andFindAll_returnsInsertedNotice() {
        Instant start = Instant.parse("2026-01-01T10:00:00Z");
        Instant end = Instant.parse("2026-01-01T12:00:00Z");

        Notice inserted = noticeDao.insert(NoticeType.ALERT, "Test content", start, end);

        assertThat(inserted.id()).isNotNull();
        assertThat(inserted.type()).isEqualTo(NoticeType.ALERT);
        assertThat(inserted.content()).isEqualTo("Test content");
        assertThat(inserted.startTime()).isEqualTo(start);
        assertThat(inserted.endTime()).isEqualTo(end);

        List<Notice> all = noticeDao.findAll();
        assertThat(all).hasSize(1);
        assertThat(all.get(0).id()).isEqualTo(inserted.id());
    }

    @Test
    void insert_multipleNotices_findAllReturnsAll() {
        noticeDao.insert(NoticeType.ALERT, "Alert 1", Instant.now(), Instant.now());
        noticeDao.insert(NoticeType.TIMED, "Timed 1", Instant.now(), Instant.now());
        noticeDao.insert(NoticeType.SINGLE, "Single 1", Instant.now(), Instant.now());

        List<Notice> all = noticeDao.findAll();

        assertThat(all).hasSize(3);
    }

    @Test
    void update_existingNotice_returnsUpdatedNotice() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT, "Original", Instant.now(), Instant.now());
        UUID id = inserted.id();

        Optional<Notice> updated = noticeDao.update(id, "Updated", Instant.now(), Instant.now());

        assertThat(updated).isPresent();
        assertThat(updated.get().id()).isEqualTo(id);
        assertThat(updated.get().type()).isEqualTo(NoticeType.ALERT);
        assertThat(updated.get().content()).isEqualTo("Updated");
    }

    @Test
    void update_nonExistentId_returnsEmpty() {
        Optional<Notice> updated = noticeDao.update(UUID.randomUUID(), "Not exist", Instant.now(),
                Instant.now());

        assertThat(updated).isEmpty();
    }

    @Test
    void delete_existingNotice_removesFromDatabase() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT, "To delete", Instant.now(), Instant.now());
        UUID id = inserted.id();

        noticeDao.delete(id);

        List<Notice> all = noticeDao.findAll();
        assertThat(all).isEmpty();
    }

    @Test
    void delete_nonExistentId_doesNotThrow() {
        noticeDao.delete(UUID.randomUUID());

        List<Notice> all = noticeDao.findAll();
        assertThat(all).isEmpty();
    }

    @Test
    void insert_withNullTimes_succeeds() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT, "Content", null, null);

        assertThat(inserted.startTime()).isNull();
        assertThat(inserted.endTime()).isNull();
    }

    @Test
    void update_preservesOtherNotices() {
        Notice notice1 = noticeDao.insert(NoticeType.ALERT, "Notice 1", Instant.now(), Instant.now());
        Notice notice2 = noticeDao.insert(NoticeType.TIMED, "Notice 2", Instant.now(), Instant.now());

        noticeDao.update(notice1.id(), "Updated 1", Instant.now(), Instant.now());

        List<Notice> all = noticeDao.findAll();
        assertThat(all).hasSize(2);
        assertThat(all).anyMatch(n -> n.content().equals("Notice 2"));
        assertThat(all).anyMatch(n -> n.content().equals("Updated 1"));
    }
}

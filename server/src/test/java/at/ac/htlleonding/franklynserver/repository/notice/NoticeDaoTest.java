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
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeContent;
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

    private static List<NoticeContent> en(String content) {
        return List.of(new NoticeContent("en", content));
    }

    private static String enContent(Notice notice) {
        return notice.contents().stream().filter(c -> c.language().equals("en")).findFirst().orElseThrow()
                .content();
    }

    @Test
    void insert_andFindAll_returnsInsertedNotice() {
        Instant start = Instant.parse("2026-01-01T10:00:00Z");
        Instant end = Instant.parse("2026-01-01T12:00:00Z");

        Notice inserted = noticeDao.insert(NoticeType.ALERT, en("Test content"), start, end);

        assertThat(inserted.id()).isNotNull();
        assertThat(inserted.type()).isEqualTo(NoticeType.ALERT);
        assertThat(inserted.contents()).containsExactly(new NoticeContent("en", "Test content"));
        assertThat(inserted.startTime()).isEqualTo(start);
        assertThat(inserted.endTime()).isEqualTo(end);

        List<Notice> all = noticeDao.findAll();
        assertThat(all).hasSize(1);
        assertThat(all.get(0).id()).isEqualTo(inserted.id());
        assertThat(all.get(0).contents()).containsExactly(new NoticeContent("en", "Test content"));
    }

    @Test
    void insert_multipleLanguages_returnsAllContents() {
        Notice inserted = noticeDao.insert(NoticeType.SINGLE,
                List.of(new NoticeContent("en", "Hello"), new NoticeContent("de", "Hallo")), null, null);

        assertThat(inserted.contents()).containsExactly(new NoticeContent("de", "Hallo"),
                new NoticeContent("en", "Hello"));
        assertThat(noticeDao.findById(inserted.id())).get().extracting(Notice::contents)
                .isEqualTo(inserted.contents());
    }

    @Test
    void insert_multipleNotices_findAllReturnsAll() {
        noticeDao.insert(NoticeType.ALERT, en("Alert 1"), Instant.now(), Instant.now());
        noticeDao.insert(NoticeType.TIMED, en("Timed 1"), Instant.now(), Instant.now());
        noticeDao.insert(NoticeType.SINGLE, en("Single 1"), Instant.now(), Instant.now());

        List<Notice> all = noticeDao.findAll();

        assertThat(all).hasSize(3);
        assertThat(all).allMatch(n -> n.contents().size() == 1);
    }

    @Test
    void update_existingNotice_returnsUpdatedNotice() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT, en("Original"), Instant.now(), Instant.now());
        UUID id = inserted.id();

        Optional<Notice> updated = noticeDao.update(id, en("Updated"), Instant.now(), Instant.now());

        assertThat(updated).isPresent();
        assertThat(updated.get().id()).isEqualTo(id);
        assertThat(updated.get().type()).isEqualTo(NoticeType.ALERT);
        assertThat(updated.get().contents()).containsExactly(new NoticeContent("en", "Updated"));
    }

    @Test
    void update_withContents_replacesAllLanguages() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT,
                List.of(new NoticeContent("en", "Hello"), new NoticeContent("de", "Hallo")), null, null);

        Optional<Notice> updated = noticeDao.update(inserted.id(), List.of(new NoticeContent("de", "Servus")), null,
                null);

        assertThat(updated).get().extracting(Notice::contents)
                .isEqualTo(List.of(new NoticeContent("de", "Servus")));
    }

    @Test
    void update_withNullContents_keepsContents() {
        Instant end = Instant.parse("2026-01-01T12:00:00Z");
        Notice inserted = noticeDao.insert(NoticeType.TIMED, en("Keep me"), Instant.now(), Instant.now());

        Optional<Notice> updated = noticeDao.update(inserted.id(), null, inserted.startTime(), end);

        assertThat(updated).isPresent();
        assertThat(updated.get().endTime()).isEqualTo(end);
        assertThat(updated.get().contents()).containsExactly(new NoticeContent("en", "Keep me"));
    }

    @Test
    void update_nonExistentId_returnsEmpty() {
        Optional<Notice> updated = noticeDao.update(UUID.randomUUID(), en("Not exist"), Instant.now(),
                Instant.now());

        assertThat(updated).isEmpty();
    }

    @Test
    void delete_existingNotice_removesFromDatabase() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT, en("To delete"), Instant.now(), Instant.now());
        UUID id = inserted.id();

        noticeDao.delete(id);

        List<Notice> all = noticeDao.findAll();
        assertThat(all).isEmpty();
        assertThat(noticeDao.findContents(id)).isEmpty();
    }

    @Test
    void delete_nonExistentId_doesNotThrow() {
        noticeDao.delete(UUID.randomUUID());

        List<Notice> all = noticeDao.findAll();
        assertThat(all).isEmpty();
    }

    @Test
    void insert_withNullTimes_succeeds() {
        Notice inserted = noticeDao.insert(NoticeType.ALERT, en("Content"), null, null);

        assertThat(inserted.startTime()).isNull();
        assertThat(inserted.endTime()).isNull();
    }

    @Test
    void update_preservesOtherNotices() {
        Notice notice1 = noticeDao.insert(NoticeType.ALERT, en("Notice 1"), Instant.now(), Instant.now());
        noticeDao.insert(NoticeType.TIMED, en("Notice 2"), Instant.now(), Instant.now());

        noticeDao.update(notice1.id(), en("Updated 1"), Instant.now(), Instant.now());

        List<Notice> all = noticeDao.findAll();
        assertThat(all).hasSize(2);
        assertThat(all).anyMatch(n -> enContent(n).equals("Notice 2"));
        assertThat(all).anyMatch(n -> enContent(n).equals("Updated 1"));
    }
}

package at.ac.htlleonding.franklynserver.repository.notice;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMappers;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindMethods;
import org.jdbi.v3.sqlobject.statement.SqlBatch;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;
import org.jdbi.v3.sqlobject.transaction.Transaction;

import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeContent;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;

@RegisterConstructorMappers(value = {@RegisterConstructorMapper(NoticeDao.NoticeRow.class),
    @RegisterConstructorMapper(NoticeDao.NoticeContentRow.class),
    @RegisterConstructorMapper(NoticeContent.class)})
public interface NoticeDao {

    record NoticeRow(UUID id, NoticeType type, Instant startTime, Instant endTime) {
        Notice withContents(List<NoticeContent> contents) {
            return new Notice(id, type, startTime, endTime, contents);
        }
    }

    record NoticeContentRow(UUID noticeId, String language, String content) {
    }

    @SqlQuery("""
            SELECT id, type::text, start_time, end_time FROM fr_notice
            """)
    List<NoticeRow> findAllRows();

    @SqlQuery("""
            SELECT id, type::text, start_time, end_time FROM fr_notice
            WHERE id = :id
            """)
    Optional<NoticeRow> findRowById(@Bind("id") UUID id);

    @SqlQuery("""
            SELECT notice_id, language, content FROM fr_notice_content
            ORDER BY language
            """)
    List<NoticeContentRow> findAllContents();

    @SqlQuery("""
            SELECT language, content FROM fr_notice_content
            WHERE notice_id = :noticeId
            ORDER BY language
            """)
    List<NoticeContent> findContents(@Bind("noticeId") UUID noticeId);

    @SqlQuery("""
            INSERT INTO fr_notice (id, type, start_time, end_time)
            VALUES (uuidv7(), :type::fr_notice_type, :startTime, :endTime)
            RETURNING id, type::text, start_time, end_time
            """)
    NoticeRow insertRow(@Bind("type") String type, @Bind("startTime") Instant startTime,
            @Bind("endTime") Instant endTime);

    @SqlQuery("""
            UPDATE fr_notice SET
                start_time = :startTime,
                end_time = :endTime
            WHERE id = :id
            RETURNING id, type::text, start_time, end_time
            """)
    Optional<NoticeRow> updateRow(@Bind("id") UUID id, @Bind("startTime") Instant startTime,
            @Bind("endTime") Instant endTime);

    @SqlBatch("""
            INSERT INTO fr_notice_content (notice_id, language, content)
            VALUES (:noticeId, :language, :content)
            """)
    void insertContents(@Bind("noticeId") UUID noticeId, @BindMethods List<NoticeContent> contents);

    @SqlUpdate("""
            DELETE FROM fr_notice_content WHERE notice_id = :noticeId
            """)
    void deleteContents(@Bind("noticeId") UUID noticeId);

    @SqlUpdate("""
            DELETE FROM fr_notice where id = :id
            """)
    void delete(@Bind("id") UUID id);

    @Transaction
    default List<Notice> findAll() {
        Map<UUID, List<NoticeContent>> contentsByNotice = findAllContents().stream()
                .collect(Collectors.groupingBy(NoticeContentRow::noticeId,
                        Collectors.mapping(row -> new NoticeContent(row.language(), row.content()),
                                Collectors.toList())));

        return findAllRows().stream()
                .map(row -> row.withContents(contentsByNotice.getOrDefault(row.id(), List.of())))
                .toList();
    }

    @Transaction
    default Optional<Notice> findById(UUID id) {
        return findRowById(id).map(row -> row.withContents(findContents(id)));
    }

    @Transaction
    default Notice insert(NoticeType type, List<NoticeContent> contents, Instant startTime, Instant endTime) {
        NoticeRow row = insertRow(type.getName(), startTime, endTime);
        insertContents(row.id(), contents);
        return row.withContents(findContents(row.id()));
    }

    /**
     * Updates the notice times. When {@code contents} is non-null, all existing contents are replaced by it.
     */
    @Transaction
    default Optional<Notice> update(UUID id, List<NoticeContent> contents, Instant startTime, Instant endTime) {
        Optional<NoticeRow> row = updateRow(id, startTime, endTime);
        if (row.isEmpty()) {
            return Optional.empty();
        }

        if (contents != null) {
            deleteContents(id);
            insertContents(id, contents);
        }

        return row.map(r -> r.withContents(findContents(id)));
    }
}

package at.ac.htlleonding.franklynserver.repository.notice;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;

@RegisterConstructorMapper(Notice.class)
public interface NoticeDao {

    @SqlQuery("""
            SELECT id, type::text, content, start_time, end_time FROM fr_notice
            """)
    List<Notice> findAll();

    @SqlQuery("""
            SELECT id, type::text, content, start_time, end_time FROM fr_notice
            WHERER id = :id
            """)
    Optional<Notice> findById(UUID id);

    @SqlQuery("""
            INSERT INTO fr_notice (id, type, content, start_time, end_time)
            VALUES (uuidv7(), :type::fr_notice_type, :content, :startTime, :endTime)
            RETURNING id, type::text, content, start_time, end_time
            """)
    Notice insert(String type, String content, Instant startTime,
            Instant endTime);

    default Notice insert(NoticeType type, String content, Instant startTime, Instant endTime) {
        return insert(type.getName(), content, startTime, endTime);
    }

    @SqlQuery("""
            UPDATE fr_notice SET
                content = :content,
                start_time = :startTime,
                end_time = :endTime
            WHERE id = :id
            RETURNING id, type::text, content, start_time, end_time
            """)
    Optional<Notice> update(UUID id, String content,
            Instant startTime, Instant endTime);

    @SqlUpdate("""
            DELETE FROM fr_notice where id = :id
            """)
    void delete(@Bind("id") UUID id);
}

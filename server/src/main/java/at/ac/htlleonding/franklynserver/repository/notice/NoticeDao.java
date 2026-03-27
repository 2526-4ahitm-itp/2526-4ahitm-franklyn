package at.ac.htlleonding.franklynserver.repository.notice;

import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RegisterConstructorMapper(Notice.class)
public interface NoticeDao {

    @SqlQuery("""
            SELECT id, type::text, content, start_time, end_time FROM fr_notice
            """)
    List<Notice> findAll();

    @SqlQuery("""
            INSERT INTO fr_notice (id, type, content, start_time, end_time)
            VALUES (uuidv7(), :type::fr_notice_type, :content, :start_time, :end_time)
            RETURNING id, type::text, content, start_time, end_time
            """)
    Notice insert(@Bind("type") String type, @Bind("content") String content, @Bind("start_time") Instant start_time,
            @Bind("end_time") Instant end_time);

    default Notice insert(NoticeType type, String content, Instant startTime, Instant endTime) {
        return insert(type.getName(), content, startTime, endTime);
    }

    @SqlQuery("""
            UPDATE fr_notice SET
                type = :type::fr_notice_type,
                content = :content,
                start_time = :start_time,
                end_time = :end_time
            WHERE id = :id
            RETURNING id, type::text, content, start_time, end_time
            """)
    Optional<Notice> update(@Bind("id") UUID id, @Bind("type") String type, @Bind("content") String content,
            @Bind("start_time") Instant start_time, @Bind("end_time") Instant end_time);

    default Optional<Notice> update(UUID id, NoticeType type, String content, Instant startTime, Instant endTime) {
        return update(id, type.getName(), content, startTime, endTime);
    }

    @SqlUpdate("""
            DELETE FROM fr_notice where id = :id
            """)
    void delete(@Bind("id") UUID id);
}

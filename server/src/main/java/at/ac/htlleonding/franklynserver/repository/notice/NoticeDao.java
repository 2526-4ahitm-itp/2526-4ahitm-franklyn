package at.ac.htlleonding.franklynserver.repository.notice;

import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import at.ac.htlleonding.franklynserver.repository.test.model.Test;
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
            SELECT id, type, content, start_time, end_time FROM fr_notice
            """)
    List<Notice> findAll();

    @SqlQuery("""
            INSERT INTO fr_notice (id, type, content, start_time, end_time)
            VALUES (uuidv7(), :type, :content, :start_time, :end_time)
            RETURNING id, type, content, start_time, end_time
            """)
    Notice insert(@Bind("type") NoticeType type,
                  @Bind("content") String content,
                  @Bind("start_time") Instant start_time,
                  @Bind("end_time") Instant end_time);

    @SqlQuery("""
            UPDATE fr_notice SET
                type = :type,
                content = :content,
                start_time = :start_time,
                end_time = :end_time
            WHERE id = :id
            RETURNING id, type, content, start_time, end_time
            """)
    Optional<Notice> update(@Bind("id") UUID id,
                            @Bind("type") NoticeType type,
                            @Bind("content") String content,
                            @Bind("start_time") Instant start_time,
                            @Bind("end_time") Instant end_time);

    @SqlUpdate("""
            DELETE FROM fr_notice where id = :id
            """)
    void delete(@Bind("id") UUID id);
}

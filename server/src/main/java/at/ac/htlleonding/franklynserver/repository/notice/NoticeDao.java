package at.ac.htlleonding.franklynserver.repository.notice;

import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import at.ac.htlleonding.franklynserver.repository.test.model.Test;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.statement.SqlQuery;

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
}

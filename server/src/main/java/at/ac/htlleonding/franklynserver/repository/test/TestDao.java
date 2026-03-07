package at.ac.htlleonding.franklynserver.repository.test;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindFields;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import at.ac.htlleonding.franklynserver.repository.test.model.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RegisterConstructorMapper(Test.class)
public interface TestDao {

    @SqlQuery("SELECT id, teacher_id, title, end_time, start_time FROM fr_test")
    List<Test> findAll();

    @SqlQuery("SELECT id, teacher_id, title, end_time, start_time FROM fr_test WHERE id = :id")
    Optional<Test> findById(@Bind("id") UUID id);

    @SqlQuery("""
            INSERT INTO fr_test (id, teacher_id, title, end_time, start_time)
            VALUES (uuidv7(), :teacherId, :title, :endTime, :startTime)
            RETURNING id, teacher_id, title, end_time, start_time
            """)
    Test insert(@Bind("teacherId") UUID teacherId,
            @Bind("title") String title,
            @Bind("testAccountPrefix") String testAccountPrefix,
            @Bind("endTime") java.time.Instant endTime,
            @Bind("startTime") java.time.Instant startTime);

    @SqlQuery("""
            UPDATE fr_test SET title = :title,
            end_time = :endTime, start_time = :startTime
            WHERE id = :id
            RETURNING id, teacher_id, title, end_time, start_time
            """)
    Optional<Test> update(@Bind("id") UUID id,
            @Bind("title") String title,
            @Bind("testAccountPrefix") String testAccountPrefix,
            @Bind("endTime") java.time.Instant endTime,
            @Bind("startTime") java.time.Instant startTime);

    @SqlQuery("""
            DELETE FROM fr_test WHERE id = :id
            RETURNING id, teacher_id, title, end_time, start_time
            """)
    Optional<Test> delete(@Bind("id") UUID id);
}

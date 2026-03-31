package at.ac.htlleonding.franklynserver.repository.test;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import at.ac.htlleonding.franklynserver.repository.test.model.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RegisterConstructorMapper(Test.class)
public interface TestDao {

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_test
            """)
    List<Test> findAll();

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_test WHERE id = :id
            """)
    Optional<Test> findById(UUID id);

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_test where id = :id and teacher_id = :teacherId
            """)
    Optional<Test> findByIdAndTeacherId(UUID id, UUID teacherId);

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_test WHERE pin = :pin
            """)
    Optional<Test> findByPin(Integer pin);

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_test WHERE teacher_id = :teacherId
            """)
    List<Test> findByTeacher(UUID teacherId);

    @SqlQuery("""
            insert into fr_test (id, teacher_id, title, start_time, end_time, pin)
            values (uuidv7(), :teacherId, :title, :endTime, :startTime, :pin)
            returning id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            """)
    Test insert(UUID teacherId, String title, Instant startTime, Instant endTime, Integer pin);

    @SqlQuery("""
            update fr_test set
                title = :title,
                teacher_id = :teacherId,
                start_time = :startTime,
                end_time = :endTime,
                started_at = :startedAt,
                ended_at = :endedAt
            where id = :id
            returning id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            """)
    Optional<Test> update(UUID id, String title,
            UUID teacherId, Instant startTime, Instant endTime, Instant startedAt,
            Instant endedAt);

    @SqlUpdate("""
            delete from fr_test where id = :id and teacher_id = :teacherId
            """)
    int delete(UUID id, UUID teacherId);
}

package at.ac.htlleonding.franklynserver.repository.exam;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RegisterConstructorMapper(Exam.class)
public interface ExamDao {

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_exam
            """)
    List<Exam> findAll();

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_exam WHERE id = :id
            """)
    Optional<Exam> findById(UUID id);

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_exam where id = :id and teacher_id = :teacherId
            """)
    Optional<Exam> findByIdAndTeacherId(UUID id, UUID teacherId);

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_exam WHERE pin = :pin
            """)
    Optional<Exam> findByPin(Integer pin);

    @SqlQuery("""
            select id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            from fr_exam WHERE teacher_id = :teacherId
            """)
    List<Exam> findByTeacher(UUID teacherId);

    @SqlQuery("""
            insert into fr_exam (id, teacher_id, title, start_time, end_time, pin)
            values (uuidv7(), :teacherId, :title, :startTime, :endTime, :pin)
            returning id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            """)
    Exam insert(UUID teacherId, String title, Instant startTime, Instant endTime, Integer pin);

    @SqlQuery("""
            update fr_exam set
                title = :title,
                teacher_id = :teacherId,
                start_time = :startTime,
                end_time = :endTime,
                started_at = :startedAt,
                ended_at = :endedAt
            where id = :id
            returning id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            """)
    Optional<Exam> update(UUID id, String title,
            UUID teacherId, Instant startTime, Instant endTime, Instant startedAt,
            Instant endedAt);

    @SqlQuery("""
            update fr_exam set
                start_time = :startTime,
                end_time = :endTime
            where id = :id
            returning id, teacher_id, title, start_time, end_time, started_at, ended_at, pin
            """)
    Optional<Exam> updateSchedule(UUID id, Instant startTime, Instant endTime);

    @SqlUpdate("""
            delete from fr_exam where id = :id and teacher_id = :teacherId
            """)
    int delete(UUID id, UUID teacherId);
}

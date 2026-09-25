package at.ac.htlleonding.franklynserver.repository.exam;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.jdbi.v3.sqlobject.config.KeyColumn;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.config.ValueColumn;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;

@RegisterConstructorMapper(ExamSession.class)
public interface ExamSessionDao {

    @SqlQuery("""
            select student_id, sentinel_id, exam_id, video_file_path, video_status
            from fr_exam_sessions
            where exam_id = :examId
            """)
    List<ExamSession> findByExamId(UUID examId);

    @SqlQuery("""
            select student_id, sentinel_id, exam_id, video_file_path, video_status
            from fr_exam_sessions
            where sentinel_id = :sentinelId
            """)
    Optional<ExamSession> findBySentinelId(@Bind("sentinelId") UUID sentinelId);

    @SqlUpdate("""
            insert into fr_exam_sessions (student_id, sentinel_id, exam_id)
            values (:studentId, :sentinelId, :examId)
            """)
    void insert(@Bind("studentId") UUID studentId, @Bind("sentinelId") UUID sentinelId, @Bind("examId") UUID examId);

    @SqlQuery("""
            select student_id, sentinel_id, exam_id, video_file_path, video_status
            from fr_exam_sessions
            where student_id = :studentId
            """)
    Optional<ExamSession> findByStudent(@Bind("studentId") UUID studentId);

    @SqlUpdate("""
            update fr_exam_sessions
            set video_status = 'PENDING', video_file_path = null
            where sentinel_id = :sentinelId
            """)
    void setPendingStatus(@Bind("sentinelId") UUID sentinelId);

    @SqlUpdate("""
            update fr_exam_sessions
            set video_status = :status, video_file_path = :filePath
            where sentinel_id = :sentinelId
            """)
    void updateVideo(@Bind("sentinelId") UUID sentinelId, @Bind("status") String status,
            @Bind("filePath") String filePath);

    @SqlQuery("""
            select s.student_id, s.sentinel_id, s.exam_id, s.video_file_path, s.video_status
            from fr_exam_sessions s
            join fr_exam e on e.id = s.exam_id
            where s.video_file_path is not null
              and coalesce(e.ended_at, e.end_time) < :cutoff
            """)
    List<ExamSession> findWithVideoEndedBefore(@Bind("cutoff") Instant cutoff);

    @SqlQuery("""
            select s.sentinel_id, coalesce(e.ended_at, e.end_time) as exam_end
            from fr_exam_sessions s
            join fr_exam e on e.id = s.exam_id
            """)
    @KeyColumn("sentinel_id")
    @ValueColumn("exam_end")
    Map<UUID, Instant> findExamEndsBySentinelId();

}

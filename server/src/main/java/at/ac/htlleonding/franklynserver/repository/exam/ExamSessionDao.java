package at.ac.htlleonding.franklynserver.repository.exam;

import java.util.List;
import java.util.UUID;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.statement.SqlQuery;

import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;

@RegisterConstructorMapper(ExamSession.class)
public interface ExamSessionDao {

    @SqlQuery("""
            select student_id, sentinel_id, exam_id, video_file_path
            from fr_exam_sessions
            where exam_id = :examId
            """)
    List<ExamSession> findByExamId(UUID examId);

}

package at.ac.htlleonding.franklynserver.repository.exam;

import java.time.Instant;
import java.util.UUID;

import org.jdbi.v3.core.Jdbi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;

@QuarkusTest
public class ExamDaoTest {

    @Inject
    Jdbi jdbi;

    @Inject
    ExamDao examDao;

    UUID teacher1Id = UUID.fromString("11111111-1111-1111-1111-111111111111");
    UUID teacher2Id = UUID.fromString("22222222-2222-2222-2222-222222222222");
    UUID teacher3Id = UUID.fromString("33333333-3333-3333-3333-333333333333");

    @BeforeEach
    void cleanDatabase() {
        jdbi.withHandle(handle -> {
            handle.execute("DELETE FROM fr_notice");
            handle.execute("DELETE FROM fr_exam");
            handle.execute("DELETE FROM fr_teacher");
            handle.execute("DELETE FROM fr_user");

            handle.execute("INSERT INTO fr_user (id, preferred_username, email) VALUES (?, 'teacher1', 't1@test.com')",
                    teacher1Id);
            handle.execute("INSERT INTO fr_teacher (id) VALUES (?)", teacher1Id);

            handle.execute("INSERT INTO fr_user (id, preferred_username, email) VALUES (?, 'teacher2', 't2@test.com')",
                    teacher2Id);
            handle.execute("INSERT INTO fr_teacher (id) VALUES (?)", teacher2Id);

            handle.execute("INSERT INTO fr_user (id, preferred_username, email) VALUES (?, 'teacher3', 't3@test.com')",
                    teacher3Id);
            handle.execute("INSERT INTO fr_teacher (id) VALUES (?)", teacher3Id);

            return null;
        });
    }

    @Test
    void insert_withNull_throwsValidationError() {
        final var time = Instant.now();
        Exam exam = examDao.insert(teacher1Id, "Some random test", time, time.plusSeconds(86300), 2500);
    }
}

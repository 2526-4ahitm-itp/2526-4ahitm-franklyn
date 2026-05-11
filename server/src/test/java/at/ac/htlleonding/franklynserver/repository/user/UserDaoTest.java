package at.ac.htlleonding.franklynserver.repository.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.StudentDetails;
import at.ac.htlleonding.franklynserver.repository.user.model.TeacherDetails;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserBuilder;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.repository.user.model.UserTheme;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.jdbi.v3.core.Jdbi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
class UserDaoTest {

    @Inject
    Jdbi jdbi;

    @Inject
    UserDao userDao;

    @BeforeEach
    void cleanDatabase() {
        jdbi.withHandle(handle -> {
            handle.execute("DELETE FROM fr_notice");
            handle.execute("DELETE FROM fr_exam");
            handle.execute("DELETE FROM fr_student");
            handle.execute("DELETE FROM fr_teacher");
            handle.execute("DELETE FROM fr_user");
            return null;
        });
    }

    @Test
    void insertUser_forTeacher_returnsUserWithDefaults() {
        UUID teacherId = UUID.randomUUID();
        User inserted = userDao.insertDetailedUser(newTeacherUser(teacherId, "teacher-one", "teacher1@test.com"));

        assertThat(inserted.id()).isEqualTo(teacherId);
        assertThat(inserted.role()).isEqualTo(UserRole.TEACHER);
        assertThat(inserted.theme()).isEqualTo(UserTheme.SYSTEM);
        assertThat(inserted.language()).isEqualTo("de");
        assertThat(inserted.details()).isInstanceOf(TeacherDetails.class);
    }

    @Test
    void insertUser_forStudent_returnsUserWithDefaults() {
        UUID studentId = UUID.randomUUID();
        User inserted = userDao.insertDetailedUser(newStudentUser(studentId, "student-one", "student1@test.com"));

        assertThat(inserted.id()).isEqualTo(studentId);
        assertThat(inserted.role()).isEqualTo(UserRole.STUDENT);
        assertThat(inserted.theme()).isEqualTo(UserTheme.SYSTEM);
        assertThat(inserted.language()).isEqualTo("de");
        assertThat(inserted.details()).isInstanceOf(StudentDetails.class);
    }

    @Test
    void updateUserSettings_nonExistingUser_doesNotCreateUser() {
        UUID missingId = UUID.randomUUID();
        User updateRequest = UserBuilder.builder(newTeacherUser(missingId, "ghost", "ghost@test.com"))
                .language("en")
                .theme(UserTheme.DARK)
                .build();

        userDao.updateUserSettings(updateRequest);

        assertThat(userDao.findById(missingId)).isEmpty();
    }

    @Test
    void findByIdAndType_withWrongRole_returnsEmpty() {
        UUID teacherId = UUID.randomUUID();
        userDao.insertDetailedUser(newTeacherUser(teacherId, "teacher-one", "teacher1@test.com"));

        Optional<User> studentLookup = userDao.findByIdAndType(teacherId, UserRole.STUDENT);
        Optional<User> teacherLookup = userDao.findByIdAndType(teacherId, UserRole.TEACHER);

        assertThat(studentLookup).isEmpty();
        assertThat(teacherLookup).isPresent();
    }

    @Test
    void findTypedRoleDetails_unknownId_returnsEmpty() {
        Optional<TeacherDetails> teacherDetails = userDao.findTypedRoleDetails(UUID.randomUUID(),
                TeacherDetails.class);
        Optional<StudentDetails> studentDetails = userDao.findTypedRoleDetails(UUID.randomUUID(),
                StudentDetails.class);

        assertThat(teacherDetails).isEmpty();
        assertThat(studentDetails).isEmpty();
    }

    @Test
    void insertDetailedUser_unknownRoleDetails_throws() {
        UUID userId = UUID.randomUUID();
        User user = UserBuilder.builder(newTeacherUser(userId, "teacher-one", "teacher1@test.com"))
                .details(new FakeDetails(userId))
                .build();

        assertThatThrownBy(() -> userDao.insertDetailedUser(user))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Class");
    }

    private static User newTeacherUser(UUID id, String preferredUsername, String email) {
        return new User(id, preferredUsername, email, null, null, "de", UserTheme.SYSTEM, UserRole.TEACHER,
                new TeacherDetails(id));
    }

    private static User newStudentUser(UUID id, String preferredUsername, String email) {
        return new User(id, preferredUsername, email, null, null, "de", UserTheme.SYSTEM, UserRole.STUDENT,
                new StudentDetails(id));
    }

    private record FakeDetails(UUID id) implements at.ac.htlleonding.franklynserver.repository.user.model.RoleDetails {
    }
}

package at.ac.htlleonding.franklynserver.repository.user;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;

import org.jdbi.v3.core.Jdbi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.UserTheme;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;

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
    void updateUserSettings_forTeacher_updatesThemeAndLanguage() {
        UUID teacherId = UUID.randomUUID();
        userDao.createTypedUser(newTeacher(teacherId, "teacher-one", "teacher1@test.com"), Teacher.class);

        Teacher updateRequest = new Teacher();
        updateRequest.id = teacherId;
        updateRequest.theme = UserTheme.DARK;
        updateRequest.language = "en";

        userDao.updateUserSettings(updateRequest);

        Teacher teacherFromDb = userDao.findTeacherById(teacherId).orElseThrow();
        assertThat(teacherFromDb.theme).isEqualTo(UserTheme.DARK);
        assertThat(teacherFromDb.language).isEqualTo("en");
    }

    @Test
    void updateUserSettings_updatesOnlyTargetedUser() {
        UUID firstTeacherId = UUID.randomUUID();
        UUID secondTeacherId = UUID.randomUUID();
        userDao.createTypedUser(newTeacher(firstTeacherId, "teacher-one", "teacher1@test.com"), Teacher.class);
        userDao.createTypedUser(newTeacher(secondTeacherId, "teacher-two", "teacher2@test.com"), Teacher.class);

        Teacher updateRequest = new Teacher();
        updateRequest.id = firstTeacherId;
        updateRequest.theme = UserTheme.LIGHT;
        updateRequest.language = "en";
        userDao.updateUserSettings(updateRequest);

        Teacher updatedTeacher = userDao.findTeacherById(firstTeacherId).orElseThrow();
        Teacher untouchedTeacher = userDao.findTeacherById(secondTeacherId).orElseThrow();

        assertThat(updatedTeacher.theme).isEqualTo(UserTheme.LIGHT);
        assertThat(updatedTeacher.language).isEqualTo("en");
        assertThat(untouchedTeacher.theme).isEqualTo(UserTheme.SYSTEM);
        assertThat(untouchedTeacher.language).isEqualTo("de");
    }

    @Test
    void updateUserSettings_forStudent_persistsSettingsChange() {
        UUID studentId = UUID.randomUUID();
        userDao.createTypedUser(newStudent(studentId, "student-one", "student1@test.com"), Student.class);

        Student updateRequest = new Student();
        updateRequest.id = studentId;
        updateRequest.theme = UserTheme.DARK;
        updateRequest.language = "it";
        userDao.updateUserSettings(updateRequest);

        Student studentFromDb = userDao.findStudentById(studentId).orElseThrow();
        assertThat(studentFromDb.theme).isEqualTo(UserTheme.DARK);
        assertThat(studentFromDb.language).isEqualTo("it");
    }

    private static Teacher newTeacher(UUID id, String preferredUsername, String email) {
        Teacher user = new Teacher();
        user.id = id;
        user.preferredUsername = preferredUsername;
        user.email = email;
        return user;
    }

    private static Student newStudent(UUID id, String preferredUsername, String email) {
        Student user = new Student();
        user.id = id;
        user.preferredUsername = preferredUsername;
        user.email = email;
        return user;
    }
}

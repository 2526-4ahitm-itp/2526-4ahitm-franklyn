package at.ac.htlleonding.franklynserver.repository.user;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.repository.user.model.UserSettings;
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
            handle.execute("DELETE FROM fr_settings");
            handle.execute("DELETE FROM fr_user");
            return null;
        });
    }

    @Test
    void upsertUser_forTeacher_insertsUser() {
        UUID teacherId = UUID.randomUUID();
        User inserted = userDao.upsertUser(newTeacherUser(teacherId, "teacher-one", "teacher1@test.com"));

        assertThat(inserted.id()).isEqualTo(teacherId);
        assertThat(inserted.role()).isEqualTo(UserRole.TEACHER);
        assertThat(inserted.preferredUsername()).isEqualTo("teacher-one");
        assertThat(inserted.email()).isEqualTo("teacher1@test.com");
    }

    @Test
    void upsertUser_forStudent_insertsUser() {
        UUID studentId = UUID.randomUUID();
        User inserted = userDao.upsertUser(newStudentUser(studentId, "student-one", "student1@test.com"));

        assertThat(inserted.id()).isEqualTo(studentId);
        assertThat(inserted.role()).isEqualTo(UserRole.STUDENT);
        assertThat(inserted.preferredUsername()).isEqualTo("student-one");
        assertThat(inserted.email()).isEqualTo("student1@test.com");
    }

    @Test
    void upsertUser_existingUser_updatesProfile() {
        UUID userId = UUID.randomUUID();
        userDao.upsertUser(newTeacherUser(userId, "old-name", "old@test.com"));

        User updated = userDao
                .upsertUser(new User(userId, "new-name", "new@test.com", "First", "Last", UserRole.TEACHER));

        assertThat(updated.preferredUsername()).isEqualTo("new-name");
        assertThat(updated.email()).isEqualTo("new@test.com");
        assertThat(updated.givenName()).isEqualTo("First");
        assertThat(updated.familyName()).isEqualTo("Last");

        Optional<User> found = userDao.findById(userId);
        assertThat(found).isPresent();
        assertThat(found.get().preferredUsername()).isEqualTo("new-name");
        assertThat(found.get().email()).isEqualTo("new@test.com");
        assertThat(found.get().givenName()).isEqualTo("First");
        assertThat(found.get().familyName()).isEqualTo("Last");
    }

    @Test
    void findByIdAndType_withWrongRole_returnsEmpty() {
        UUID teacherId = UUID.randomUUID();
        userDao.upsertUser(newTeacherUser(teacherId, "teacher-one", "teacher1@test.com"));

        Optional<User> studentLookup = userDao.findByIdAndType(teacherId, UserRole.STUDENT);
        Optional<User> teacherLookup = userDao.findByIdAndType(teacherId, UserRole.TEACHER);

        assertThat(studentLookup).isEmpty();
        assertThat(teacherLookup).isPresent();
    }

    @Test
    void findSettings_nonExistingUser_returnsEmpty() {
        Optional<UserSettings> settings = userDao.findSettings(UUID.randomUUID());
        assertThat(settings).isEmpty();
    }

    @Test
    void insertSettings_andFindSettings_returnsSettings() {
        UUID userId = UUID.randomUUID();
        userDao.upsertUser(newTeacherUser(userId, "teacher-settings", "settings@test.com"));

        userDao.insertSettings(new UserSettings(userId, UserTheme.SYSTEM, "de"));

        Optional<UserSettings> found = userDao.findSettings(userId);
        assertThat(found).isPresent();
        assertThat(found.get().userId()).isEqualTo(userId);
        assertThat(found.get().theme()).isEqualTo(UserTheme.SYSTEM);
        assertThat(found.get().language()).isEqualTo("de");
    }

    @Test
    void insertSettings_alreadyExists_doesNotOverwrite() {
        UUID userId = UUID.randomUUID();
        userDao.upsertUser(newTeacherUser(userId, "teacher-settings-dup", "dup@test.com"));

        userDao.insertSettings(new UserSettings(userId, UserTheme.DARK, "en"));
        userDao.insertSettings(new UserSettings(userId, UserTheme.SYSTEM, "de"));

        Optional<UserSettings> found = userDao.findSettings(userId);
        assertThat(found).isPresent();
        assertThat(found.get().theme()).isEqualTo(UserTheme.DARK);
        assertThat(found.get().language()).isEqualTo("en");
    }

    @Test
    void updateSettings_updatesThemeAndLanguage() {
        UUID userId = UUID.randomUUID();
        userDao.upsertUser(newTeacherUser(userId, "teacher-update", "update@test.com"));
        userDao.insertSettings(new UserSettings(userId, UserTheme.SYSTEM, "de"));

        UserSettings updated = userDao.updateSettings(userId, UserTheme.DARK.getName(), "en");

        assertThat(updated.userId()).isEqualTo(userId);
        assertThat(updated.theme()).isEqualTo(UserTheme.DARK);
        assertThat(updated.language()).isEqualTo("en");

        Optional<UserSettings> found = userDao.findSettings(userId);
        assertThat(found).isPresent();
        assertThat(found.get().theme()).isEqualTo(UserTheme.DARK);
        assertThat(found.get().language()).isEqualTo("en");
    }

    private static User newTeacherUser(UUID id, String preferredUsername, String email) {
        return new User(id, preferredUsername, email, null, null, UserRole.TEACHER);
    }

    private static User newStudentUser(UUID id, String preferredUsername, String email) {
        return new User(id, preferredUsername, email, null, null, UserRole.STUDENT);
    }
}

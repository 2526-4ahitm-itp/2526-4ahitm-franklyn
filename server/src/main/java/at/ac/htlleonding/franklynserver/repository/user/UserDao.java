package at.ac.htlleonding.franklynserver.repository.user;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.*;
import jakarta.enterprise.inject.spi.CDI;
import org.jdbi.v3.core.Handle;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMappers;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindMethods;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterConstructorMappers(value = {@RegisterConstructorMapper(User.class),
    @RegisterConstructorMapper(TeacherDetails.class), @RegisterConstructorMapper(StudentDetails.class)})
public interface UserDao {

    @SqlUpdate("""
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName)
            """)
    void insertUser(@BindFields User user);

    @SqlUpdate("INSERT INTO fr_student (id, school_class) VALUES (:id, :schoolClass)")
    void insertStudent(@Bind("id") UUID id, @Bind("schoolClass") String schoolClass);

    @SqlUpdate("INSERT INTO fr_teacher (id) VALUES (:id)")
    void insertTeacher(@Bind("id") UUID id);

    @RegisterFieldMapper(Teacher.class)
    @SqlQuery("""
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name, role)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName, :role::fr_user_type)
            RETURNING id, preferred_username, email, given_name, family_name, language, theme::text, role::text
            """)
    User insertUser(@BindMethods User user);

    @SqlQuery("""
            SELECT u.id, u.preferred_username, u.email, u.given_name, u.family_name, u.theme::text, u.language,
                   s.school_class
            FROM fr_user u
            JOIN fr_student s ON s.id = u.id
            WHERE u.id = :id
            """)
    Optional<User> findById(@Bind("id") UUID id);

    @Transaction
    default <T extends User> T createTypedUser(User user, Class<T> clazz) {

        insertUser(user);

        if (clazz == Student.class) {
            insertStudent(user.id, ((Student) user).schoolClass);
        } else if (clazz == Teacher.class) {
            insertTeacher(user.id);
        }

        return clazz.cast(user);
    }

    @SqlUpdate("""
            update fr_user set
                language = :language,
                theme = :theme::fr_settings_theme
            where id = :id
            """)
    void updateUserSettingsInternal(@Bind("id") UUID id, @Bind("language") String language,
            @Bind("theme") String theme);

    default void updateUserSettings(User user) {
        updateUserSettingsInternal(user.id(), user.language(), user.theme().getName());
    }

    default <T extends RoleDetails> Optional<T> findTypedRoleDetails(UUID id, Class<T> clazz) {
        var jdbi = CDI.current().select(Jdbi.class).get();

        String tableName = clazz.equals(TeacherDetails.class) ? "fr_teacher" : "fr_student";

        return jdbi.withHandle(handle -> handle.createQuery("select * from " + tableName + " where id = :id")
                .bind("id", id).mapTo(clazz).findOne());
    }

    default User insertDetailedUser(User user) {
        var jdbi = CDI.current().select(Jdbi.class).get();

        return jdbi.inTransaction(handle -> {

            UserDao dao = handle.attach(UserDao.class);
            var insertedUser = dao.insertUser(user);

            return switch (user.role()) {
                case STUDENT -> {
                    var userDetails = insertTypedRoleDetails(handle, ((StudentDetails) user.details()),
                            StudentDetails.class);
                    yield UserBuilder.builder(insertedUser).details(userDetails).build();
                }
                case TEACHER -> {
                    var userDetails = insertTypedRoleDetails(handle, (TeacherDetails) user.details(),
                            TeacherDetails.class);
                    yield UserBuilder.builder(insertedUser).details(userDetails).build();
                }
            };
        });
    }

    default <T extends RoleDetails> T insertTypedRoleDetails(Handle handle, T details, Class<T> clazz) {

        if (details instanceof TeacherDetails) {
            return handle.createQuery("insert into fr_teacher (id) values (:id) returning id").bindMethods(details)
                    .mapTo(clazz).one();
        } else if (details instanceof StudentDetails) {
            return handle.createQuery("insert into fr_student (id) values (:id) returning id").bindMethods(details)
                    .mapTo(clazz).one();
        }

        throw new RuntimeException(
                String.format("Class %s is not of type TeacherDetails or StudentDetails", clazz.getName()));

    }
}

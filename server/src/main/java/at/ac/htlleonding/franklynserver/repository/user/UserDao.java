package at.ac.htlleonding.franklynserver.repository.user;

import java.util.Optional;
import java.util.UUID;

import org.jdbi.v3.sqlobject.config.RegisterFieldMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindFields;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;
import org.jdbi.v3.sqlobject.transaction.Transaction;

import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;

@RegisterFieldMapper(User.class)
public interface UserDao {

    @SqlUpdate("""
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName)
            """)
    void insertUser(@BindFields User user);

    @SqlUpdate("INSERT INTO fr_student (id) VALUES (:id)")
    void insertStudent(@Bind("id") UUID id);

    @SqlUpdate("INSERT INTO fr_teacher (id) VALUES (:id)")
    void insertTeacher(@Bind("id") UUID id);

    @RegisterFieldMapper(Teacher.class)
    @SqlQuery("""
            SELECT u.id, u.preferred_username, u.email, u.given_name, u.family_name
            FROM fr_user u
            JOIN fr_teacher t ON t.id = u.id
            WHERE u.id = :id
            """)
    Optional<Teacher> findTeacherById(@Bind("id") UUID id);

    @RegisterFieldMapper(Student.class)
    @SqlQuery("""
            SELECT u.id, u.preferred_username, u.email, u.given_name, u.family_name
            FROM fr_user u
            JOIN fr_student s ON s.id = u.id
            WHERE u.id = :id
            """)
    Optional<Student> findStudentById(@Bind("id") UUID id);

    @Transaction
    default <T extends User> T createTypedUser(User user, Class<T> clazz) {

        insertUser(user);

        if (clazz == Student.class) {
            insertStudent(user.id);
        } else if (clazz == Teacher.class) {
            insertTeacher(user.id);
        }

        return clazz.cast(user);
    }
}

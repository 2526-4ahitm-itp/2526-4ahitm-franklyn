package at.ac.htlleonding.franklynserver.repository.user;

import org.jdbi.v3.sqlobject.config.RegisterBeanMapper;
import org.jdbi.v3.sqlobject.customizer.BindBean;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;
import org.jdbi.v3.sqlobject.transaction.Transaction;
import org.jose4j.jwk.Use;

import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;

@RegisterBeanMapper(User.class)
public interface UserDao {

    @SqlUpdate("""
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName)
            RETURNING id, preferred_username, email, given_name, family_name
            """)
    User insertUser(@BindBean User user);

    @RegisterBeanMapper(Student.class)
    @SqlUpdate("""
            INSERT INTO fr_student (id) VALUES (:id)
            """)
    void insertStudent(@BindBean Student student);

    @RegisterBeanMapper(Teacher.class)
    @SqlUpdate("""
            INSERT INTO fr_teacher (id) VALUES (:id)
            """)
    void insertTeacher(@BindBean Teacher teacher);

    @Transaction
    default <T extends User> T createTypedUser(User user, Class<T> clazz) {
        user = insertUser(user);

        if (clazz == Student.class) {
            insertStudent((Student) user);
        } else if (clazz == Teacher.class) {
            insertTeacher((Teacher) user);
        }

        return clazz.cast(user);
    }
}

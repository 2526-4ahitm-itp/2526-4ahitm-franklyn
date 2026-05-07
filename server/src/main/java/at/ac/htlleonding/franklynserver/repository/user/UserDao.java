package at.ac.htlleonding.franklynserver.repository.user;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.*;
import jakarta.enterprise.inject.spi.CDI;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.config.RegisterFieldMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindFields;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterFieldMapper(User.class)
public interface UserDao {

    @SqlUpdate("""
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name, type)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName, :type)
            RETURNING id, preferred_username, email, given_name, family_name, type, language, theme::text, type
            """)
    User insertUser(@BindFields User user);

    @SqlQuery("""
            SELECT id, preferred_username, email, given_name, family_name, theme::text, language, type
            FROM fr_user
            WHERE id = :id
            """)
    Optional<User> findById(@Bind("id") UUID id);

    @SqlQuery("""
            SELECT id, preferred_username, email, given_name, family_name, theme::text, language, type
            FROM fr_user
            WHERE id = :id AND type = :type
            """)
    Optional<User> findByIdAndType(@Bind("id") UUID id, @Bind("type") UserRole type);

    @SqlUpdate("""
            update fr_user set
                language = :language,
                theme = :theme::fr_settings_theme
            where id = :id
            """)

    void updateUserSettingsInternal(
            @Bind("id") UUID id,
            @Bind("language") String language,
            @Bind("theme") String theme);

    default void updateUserSettings(User user) {
        updateUserSettingsInternal(user.id(), user.language(), user.theme().getName());
    }


    default <T extends RoleDetails> Optional<T> findTypedRoleDetails( UUID id, Class<T> clazz) {
        var jdbi = CDI.current().select( Jdbi.class ).get();

        String tableName = clazz.equals( TeacherDetails.class )
                ? "fr_teacher" : "fr_student";

        return jdbi.withHandle( handle -> handle.createQuery( "select * from " + tableName + " where id = :id")
                .bind( "id", id )
                .mapTo( clazz )
                .findOne() );
    }
}

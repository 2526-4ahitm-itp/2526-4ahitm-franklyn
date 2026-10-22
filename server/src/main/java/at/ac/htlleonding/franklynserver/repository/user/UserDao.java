package at.ac.htlleonding.franklynserver.repository.user;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.repository.user.model.UserSettings;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMappers;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindMethods;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterConstructorMappers(value = {@RegisterConstructorMapper(User.class),
    @RegisterConstructorMapper(UserSettings.class)})
public interface UserDao {

    @SqlQuery("""
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name, role)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName, :role::fr_user_type)
            ON CONFLICT (id) DO UPDATE SET
                preferred_username = EXCLUDED.preferred_username,
                email = EXCLUDED.email,
                given_name = EXCLUDED.given_name,
                family_name = EXCLUDED.family_name
            RETURNING id, preferred_username, email, given_name, family_name, role::text
            """)
    User upsertUser(@BindMethods User user);

    @SqlQuery("""
            SELECT id, preferred_username, email, given_name, family_name, role::text
            FROM fr_user
            WHERE id = :id
            """)
    Optional<User> findById(@Bind("id") UUID id);

    @SqlQuery("""
            SELECT id, preferred_username, email, given_name, family_name, role::text
            FROM fr_user
            WHERE id = :id AND role = :role::fr_user_type
            """)
    Optional<User> findByIdAndType(@Bind("id") UUID id, @Bind("role") UserRole role);

    @SqlQuery("""
            SELECT user_id, theme::text, language
            FROM fr_settings
            WHERE user_id = :userId
            """)
    Optional<UserSettings> findSettings(@Bind("userId") UUID userId);

    @SqlUpdate("""
            INSERT INTO fr_settings (user_id, theme, language)
            VALUES (:userId, lower(:theme)::fr_settings_theme, :language)
            ON CONFLICT (user_id) DO NOTHING
            """)
    void insertSettings(@BindMethods UserSettings settings);

    @SqlQuery("""
            UPDATE fr_settings
            SET theme = lower(:theme)::fr_settings_theme,
                language = :language
            WHERE user_id = :userId
            RETURNING user_id, theme::text, language
            """)
    UserSettings updateSettings(@Bind("userId") UUID userId, @Bind("theme") String theme,
            @Bind("language") String language);
}

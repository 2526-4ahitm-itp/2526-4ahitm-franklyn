package at.ac.htlleonding.franklynserver.repository.user;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.*;
import jakarta.enterprise.inject.spi.CDI;
import org.jdbi.v3.core.Handle;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.config.RegisterConstructorMappers;
import org.jdbi.v3.sqlobject.config.RegisterFieldMapper;
import org.jdbi.v3.sqlobject.customizer.Bind;
import org.jdbi.v3.sqlobject.customizer.BindFields;
import org.jdbi.v3.sqlobject.customizer.BindMethods;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

@RegisterConstructorMappers(
        value = { @RegisterConstructorMapper( User.class ),
                @RegisterConstructorMapper( TeacherDetails.class ),
                @RegisterConstructorMapper( StudentDetails.class ) }
)
public interface UserDao {

    @SqlQuery( """
            INSERT INTO fr_user (id, preferred_username, email, given_name, family_name, role)
            VALUES (:id, :preferredUsername, :email, :givenName, :familyName, :role::fr_user_type)
            RETURNING id, preferred_username, email, given_name, family_name, language, theme::text, role::text
            """ )
    User insertUser( @BindMethods User user );

    @SqlQuery( """
            SELECT id, preferred_username, email, given_name, family_name, theme::text, language, role::text
            FROM fr_user
            WHERE id = :id
            """ )
    Optional<User> findById( @Bind( "id" ) UUID id );

    @SqlQuery( """
            SELECT id, preferred_username, email, given_name, family_name, theme::text, language, role::text
            FROM fr_user
            WHERE id = :id AND role = :role::fr_user_type
            """ )
    Optional<User> findByIdAndType( @Bind( "id" ) UUID id, @Bind( "role" ) UserRole role );

    @SqlUpdate( """
            update fr_user set
                language = :language,
                theme = :theme::fr_settings_theme
            where id = :id
            """ )
    void updateUserSettingsInternal(
            @Bind( "id" ) UUID id,
            @Bind( "language" ) String language,
            @Bind( "theme" ) String theme );

    default void updateUserSettings( User user ) {
        updateUserSettingsInternal( user.id(), user.language(), user.theme().getName() );
    }

    default <T extends RoleDetails> Optional<T> findTypedRoleDetails( UUID id, Class<T> clazz ) {
        var jdbi = CDI.current().select( Jdbi.class ).get();

        String tableName = clazz.equals( TeacherDetails.class )
                ? "fr_teacher" : "fr_student";

        return jdbi.withHandle( handle -> handle.createQuery( "select * from " + tableName + " where id = :id" )
                .bind( "id", id )
                .mapTo( clazz )
                .findOne() );
    }

    default User insertDetailedUser( User user ) {
        var jdbi = CDI.current().select( Jdbi.class ).get();

        return jdbi.inTransaction( handle -> {

            UserDao dao = handle.attach( UserDao.class );
            var insertedUser = dao.insertUser( user );

            return switch( user.role() ) {
                case STUDENT -> {
                    var userDetails = insertTypedRoleDetails( handle, ( (StudentDetails) user.details() ), StudentDetails.class );
                    yield UserBuilder.builder( insertedUser ).details( userDetails ).build();
                }
                case TEACHER -> {
                    var userDetails = insertTypedRoleDetails( handle, (TeacherDetails) user.details(), TeacherDetails.class );
                    yield UserBuilder.builder( insertedUser ).details( userDetails ).build();
                }
            };
        } );
    }

    default <T extends RoleDetails> T insertTypedRoleDetails( Handle handle, T details, Class<T> clazz ) {

        if( details instanceof TeacherDetails ) {
            return handle.createQuery( "insert into fr_teacher (id) values (:id) returning id" )
                    .bindMethods( details )
                    .mapTo( clazz )
                    .one();
        } else if( details instanceof StudentDetails ) {
            return handle.createQuery( "insert into fr_student (id) values (:id) returning id" )
                    .bindMethods( details )
                    .mapTo( clazz )
                    .one();
        }

        throw new RuntimeException(
                String.format( "Class %s is not of type TeacherDetails or StudentDetails", clazz.getName() ) );


    }
}

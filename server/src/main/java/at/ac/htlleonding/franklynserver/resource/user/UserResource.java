package at.ac.htlleonding.franklynserver.resource.user;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.RoleDetails;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserBuilder;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.user.model.UpdateUserSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import org.eclipse.microprofile.graphql.*;

import java.util.Optional;


@GraphQLApi
@ApplicationScoped
public class UserResource {

    @Inject
    OidcUserService userService;

    @Inject
    UserDao userDao;

    @Mutation
    public @NonNull User updateSettings( @Valid @NonNull UpdateUserSettings settingsInput )
            throws GraphQLBusinessException {
        User t = userService.resolveUser( UserRole.TEACHER );

        User newUser = UserBuilder.builder( t )
                .theme(settingsInput.theme())
                .language(settingsInput.language())
                .build();

        userDao.updateUserSettings( t );
        return t;
    }

    @Query
    public @NonNull User user()
            throws GraphQLBusinessException {
        return userService.resolveUser();
    }

    @NonNull
    public Optional<? extends RoleDetails> roleDetails( @Source User user ) {
        return userDao.findTypedRoleDetails( user.id(), user.role().roleClass );
    }
}

package at.ac.htlleonding.franklynserver.resource.user;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatchException;
import at.ac.htlleonding.franklynserver.resource.user.model.UpdateUserSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.NonNull;
import org.eclipse.microprofile.graphql.Query;

import java.util.UUID;


@GraphQLApi
@ApplicationScoped
public class UserResource {

    @Inject
    OidcUserService userService;

    @Inject
    UserDao userDao;

    @Mutation
    public @NonNull User updateSettings(@Valid @NonNull UpdateUserSettings settingsInput)
            throws GraphQLBusinessException {
        User t = userService.resolveUser(Teacher.class);
        t.language = settingsInput.language();
        t.theme = settingsInput.theme();

        userDao.updateUserSettings(t);
        return t;
    }
    @Query
    public @NonNull User userInfo()
        throws GraphQLBusinessException {
        return userService.resolveUser();
    }
}

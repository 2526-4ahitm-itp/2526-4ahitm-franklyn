package at.ac.htlleonding.franklynserver.resource.user;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatchException;
import at.ac.htlleonding.franklynserver.resource.user.model.UpdateUserSettings;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import org.eclipse.microprofile.graphql.NonNull;

public class UserResource {

    @Inject
    OidcUserService userService;

    @Inject
    UserDao userDao;

    public @NonNull User updateSettings(@Valid @NonNull UpdateUserSettings settingsInput)
            throws GraphQLBusinessException {
        User t = userService.resolveJwtUser(Teacher.class);

        if (t.getClass() != Teacher.class) {
            throw new UserTypeMismatchException(Teacher.class, t.getClass(), t.id);
        }

        t.language = settingsInput.language();
        t.theme = settingsInput.theme();

        userDao.updateUserSettings(t);
        return t;
    }
}

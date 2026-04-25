package at.ac.htlleonding.franklynserver.resource.setting;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatchException;
import at.ac.htlleonding.franklynserver.resource.setting.model.UpdateUserSettings;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import org.eclipse.microprofile.graphql.NonNull;
import org.jdbi.v3.core.statement.Update;

public class SettingResource {

    @Inject
    OidcUserService userService;

    @Inject
    UserDao userDao;

    public @NonNull UpdateUserSettings updateSettings(@Valid @NonNull UpdateUserSettings settingsInput) throws GraphQLBusinessException {
        Teacher t = userService.resolveJwtUser(Teacher.class);

        if (t.getClass() != Teacher.class) {
            throw new UserTypeMismatchException(Teacher.class, t.getClass(), t.id);
        }

        // TODO: return userDao.updateSettings(settingsInput, t.id) or whatever when implemented in database

        return null;
    }
}

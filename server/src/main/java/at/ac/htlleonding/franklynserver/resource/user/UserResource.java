package at.ac.htlleonding.franklynserver.resource.user;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.exam.ExamDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.repository.user.model.UserSettings;
import at.ac.htlleonding.franklynserver.repository.user.model.UserTheme;
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
import org.eclipse.microprofile.graphql.Source;

@GraphQLApi
@ApplicationScoped
public class UserResource {

    @Inject
    OidcUserService userService;

    @Inject
    UserDao userDao;

    @Inject
    ExamDao examDao;

    @Mutation
    public @NonNull UserSettings updateSettings(@Valid @NonNull UpdateUserSettings settingsInput)
            throws GraphQLBusinessException {
        User u = userService.resolveUser(UserRole.TEACHER);
        return userDao.updateSettings(u.id(), settingsInput.theme().getName(), settingsInput.language());
    }

    @Query
    public @NonNull User user() throws GraphQLBusinessException {
        return userService.resolveJwtUser();
    }

    @Query
    public Optional<User> userById(@NonNull UUID id) {
        return userDao.findById(id);
    }

    public @NonNull UserSettings settings(@Source User user) {
        return userDao.findSettings(user.id()).orElse(new UserSettings(user.id(), UserTheme.SYSTEM, "de"));
    }

    public @NonNull List<@NonNull Exam> exams(@Source User user) throws GraphQLBusinessException {
        if (user.role() != UserRole.TEACHER) {
            throw new UserTypeMismatchException(UserRole.TEACHER, user.role(), user.id());
        }
        return examDao.findByTeacher(user.id());
    }
}

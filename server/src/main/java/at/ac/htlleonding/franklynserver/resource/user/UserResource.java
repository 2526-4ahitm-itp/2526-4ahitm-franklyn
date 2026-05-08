package at.ac.htlleonding.franklynserver.resource.user;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.exam.ExamDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.*;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.user.model.UpdateUserSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import org.eclipse.microprofile.graphql.*;

import java.util.List;
import java.util.Optional;


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
    public @NonNull User updateSettings( @Valid @NonNull UpdateUserSettings settingsInput )
            throws GraphQLBusinessException {
        User t = userService.resolveUser( UserRole.TEACHER );

        User newUser = UserBuilder.builder( t )
                .theme( settingsInput.theme() )
                .language( settingsInput.language() )
                .build();

        userDao.updateUserSettings( newUser );
        return newUser;
    }

    @Query
    public @NonNull User user()
            throws GraphQLBusinessException {
        return userService.resolveUser();
    }

    public Optional<? extends RoleDetails> roleDetails( @Source User user ) {
        return userDao.findTypedRoleDetails( user.id(), user.role().roleClass );
    }

    public @NonNull List<@NonNull Exam> exams( @Source TeacherDetails details ) {
        return examDao.findByTeacher( details.id() );
    }
}

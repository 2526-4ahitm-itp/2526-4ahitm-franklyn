package at.ac.htlleonding.franklynserver.oidc;

import java.util.Optional;
import java.util.UUID;

import io.quarkus.logging.Log;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.jwt.JsonWebToken;

import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatchException;

@RequestScoped
public class OidcUserService {

    @Inject
    UserDao userDao;

    @Inject
    SecurityIdentity identity;

    /**
     * Resolves the User of the current authentication context. This persists the
     * User or if the User already exists
     * just returns the queried User.
     * 
     * @return User
     * @throws RuntimeException
     */
    public User resolveUser() {
        User user = resolveJwtUser();

        var foundUser = findExistingUser(user.id, user.getClass());

        if (!foundUser.isEmpty())
            return foundUser.get();

        User createdUser = createUser((JsonWebToken) identity.getPrincipal(),
                user.id, user.getClass());

        return createdUser;
    }

    /**
     * Resolves the User of the current authentication context. This persists the
     * User or if the User already exists
     * just return the queried User. Aditionally, if the requested User Type does
     * not match the currently authenticated
     * User, a RuntimeException is thrown.
     * 
     * @param <T>
     *              Teacher or Student
     * @param clazz
     *              Teacher or Student
     * @return User
     * @throws UserTypeMismatchException
     * @throws RuntimeException
     */
    public <T extends User> T resolveUser(Class<T> clazz) throws GraphQLBusinessException {
        var user = resolveUser();

        if (!clazz.isInstance(user)) {
            throw new UserTypeMismatchException(clazz, user.getClass(), user.id);
        }

        Log.debugf("Resolving user id=%s, type=%s", user.id, clazz.getSimpleName());

        return clazz.cast(user);
    }

    /**
     * Resolves the User of the current authentication context purely from the jwt
     * and does not persist the resolved
     * User.
     * 
     * @return User
     * @throws RuntimeException
     */
    public User resolveJwtUser() {
        if (identity == null || identity.getPrincipal() == null) {
            throw new RuntimeException("No authentication context available or unauthenticated access detected.");
        }

        var jwt = (JsonWebToken) identity.getPrincipal();
        var id = UUID.fromString(jwt.getSubject());

        String ldapEntryDn = jwt.getClaim("distinguished_name");

        var role = UserRole.fromDistinguishedName(ldapEntryDn);

        if (role.isEmpty()) {
            throw new RuntimeException(String.format("User '%s' is no Teacher or Student", id));
        }

        User user = switch (role.get()) {
            case STUDENT -> new Student();
            case TEACHER -> new Teacher();
        };

        user.id = id;
        user.preferredUsername = jwt.getClaim("preferred_username");
        user.email = jwt.getClaim("email");
        user.givenName = jwt.getClaim("given_name");
        user.familyName = jwt.getClaim("family_name");

        return user;
    }

    /**
     * Resolves the User of the current authentication context purely from the jwt
     * and does not persist the resolved
     * User. If the resolved User is not of type 'clazz', a
     * UserTypeMismatchException exception is thrown.
     * 
     * @param <T>
     *              Teacher or Student
     * @param clazz
     *              Teacher or Student
     * @return User
     * @throws UserTypeMismatchException
     * @throws RuntimeException
     */
    public <T extends User> T resolveJwtUser(Class<T> clazz) throws GraphQLBusinessException {
        User user = resolveJwtUser();

        if (!clazz.isInstance(user)) {
            throw new UserTypeMismatchException(clazz, user.getClass(), user.id);
        }

        return clazz.cast(user);
    }

    private <T extends User> Optional<T> findExistingUser(UUID id, Class<T> clazz) {
        Log.debugf("Looking up existing %s with id=%s", clazz.getSimpleName(), id);

        Optional<T> result;

        if (clazz == Teacher.class)
            result = userDao.findTeacherById(id).map(clazz::cast);
        else
            result = userDao.findStudentById(id).map(clazz::cast);

        if (result.isPresent()) {
            Log.debugf("Found existing %s: %s", clazz.getSimpleName(), result.get());
        } else {
            Log.debugf("No existing %s found for id=%s", clazz.getSimpleName(), id);
        }

        return result;
    }

    private <T extends User> T createUser(JsonWebToken jwt, UUID id, Class<T> clazz) {
        User user;

        if (clazz == Teacher.class)
            user = new Teacher();
        else
            user = new Student();

        user.id = id;
        user.preferredUsername = jwt.getClaim("preferred_username");
        user.email = jwt.getClaim("email");
        user.givenName = jwt.getClaim("given_name");
        user.familyName = jwt.getClaim("family_name");

        Log.infof("Auto-provisioning %s '%s' (id=%s, email=%s)", clazz.getSimpleName(), user.preferredUsername, id,
                user.email);
        T created = userDao.createTypedUser(user, clazz);
        Log.infof("Successfully provisioned %s '%s'", clazz.getSimpleName(), user.preferredUsername);
        return created;
    }
}

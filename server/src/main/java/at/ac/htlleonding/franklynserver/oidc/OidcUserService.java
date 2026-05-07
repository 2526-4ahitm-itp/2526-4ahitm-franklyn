package at.ac.htlleonding.franklynserver.oidc;

import java.util.Optional;
import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.*;
import io.quarkus.logging.Log;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.jwt.JsonWebToken;

import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatchException;

@RequestScoped
public class OidcUserService {

    @Inject
    UserDao userDao;

    @Inject
    SecurityIdentity identity;

    /**
     * Resolves the User for the current authentication context.
     * If the user already exists, it is returned; otherwise a new user is
     * auto-provisioned from the current JWT.
     *
     * @return User
     * @throws RuntimeException
     */
    public User resolveUser() {
        User user = resolveJwtUser();

        var foundUser = findExistingUser(user.id(), user.role());

        return foundUser.orElseGet( () -> createUser( (JsonWebToken) identity.getPrincipal(),
                user.id(), user.role() ) );

    }

    /**
     * Resolves the User for the current authentication context.
     * If the user already exists, it is returned; otherwise a new user is
     * auto-provisioned from the current JWT. If the resolved user role does not
     * match the expected role, a UserTypeMismatchException is thrown.
     *
     * @param role
     *              expected user role
     * @return User
     * @throws UserTypeMismatchException
     * @throws RuntimeException
     */
    public User resolveUser(UserRole role) throws GraphQLBusinessException {
        var user = resolveUser();

        if (!user.role().equals(role)) {
            throw new UserTypeMismatchException(role, user.role(), user.id());
        }

        Log.debugf("Resolving user id=%s, type=%s", user.id(), user.role());

        return user;
    }

    /**
     * Resolves the User for the current authentication context purely from the JWT
     * and does not persist the resolved user.
     *
     * @return User
     * @throws RuntimeException - Thrown when UserRole::fromDistinguishedName returns None
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

        return new User(id,
                jwt.getClaim("preferred_username"),
                jwt.getClaim("email"),
                jwt.getClaim("given_name"),
                jwt.getClaim("family_name"),
                null,
                null,
                role.get(),
                null);
    }

    /**
     * Resolves the User for the current authentication context purely from the JWT
     * and does not persist the resolved user. If the resolved user role does not
     * match the expected role, a UserTypeMismatchException is thrown.
     *
     * @param role
     *              expected user role
     * @return User
     * @throws UserTypeMismatchException
     * @throws RuntimeException
     */
    public User resolveJwtUser(UserRole role) throws GraphQLBusinessException {
        User user = resolveJwtUser();

        if (!role.equals(user.role())) {
            throw new UserTypeMismatchException(role, user.role(), user.id());
        }

        return user;
    }

    private Optional<User> findExistingUser(UUID id, UserRole role) {
        Log.debugf("Looking up existing %s with id=%s", role, id);

        Optional<User> result = userDao.findById(id);

        if (result.isPresent()) {
            Log.debugf("Found existing %s: %s", role, result.get());
        } else {
            Log.debugf("No existing %s found for id=%s", role, id);
        }

        return result;
    }

    private User createUser(JsonWebToken jwt, UUID id, UserRole role) {

        RoleDetails roleDetails = switch (role) {
            case STUDENT -> new StudentDetails( id );
            case TEACHER -> new TeacherDetails( id );
        };

        User user = new User(id,
                jwt.getClaim("preferred_username"),
                jwt.getClaim("email"),
                jwt.getClaim("given_name"),
                jwt.getClaim("family_name"),
                null,
                null,
                role,
                roleDetails);

        Log.infof("Auto-provisioning %s '%s' (id=%s, email=%s)", role, user.preferredUsername(), id,
                user.email());
        User created = userDao.insertDetailedUser(user);
        Log.infof("Successfully provisioned %s '%s'", role, user.preferredUsername());
        return created;
    }
}

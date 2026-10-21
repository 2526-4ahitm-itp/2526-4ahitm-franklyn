package at.ac.htlleonding.franklynserver.oidc;

import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import at.ac.htlleonding.franklynserver.repository.user.model.UserSettings;
import at.ac.htlleonding.franklynserver.repository.user.model.UserTheme;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatchException;
import io.quarkus.logging.Log;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.jwt.JsonWebToken;

@RequestScoped
public class OidcUserService {

    @Inject
    UserDao userDao;

    @Inject
    SecurityIdentity identity;

    /**
     * Resolves the User for the current authentication context. The user is upserted from the current JWT and default
     * settings are ensured.
     *
     * @return User
     * @throws RuntimeException
     */
    @Transactional
    public User resolveUser() {
        User user = resolveJwtUser();
        User upserted = userDao.upsertUser(user);
        userDao.insertSettings(new UserSettings(upserted.id(), UserTheme.SYSTEM, "de"));
        return upserted;
    }

    /**
     * Resolves the User for the current authentication context. If the resolved user role does not match the expected
     * role, a UserTypeMismatchException is thrown.
     *
     * @param role
     *            expected user role
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
     * Resolves the User for the current authentication context purely from the JWT and does not persist the resolved
     * user.
     *
     * @return User
     * @throws RuntimeException
     *             - Thrown when UserRole::fromDistinguishedName returns None
     */
    public User resolveJwtUser() {
        if (identity == null || identity.getPrincipal() == null) {
            throw new RuntimeException("No authentication context available or unauthenticated access detected.");
        }

        return resolveJwtUser((JsonWebToken) identity.getPrincipal());
    }

    @Transactional
    public User resolveUser(JsonWebToken jwt) {
        User user = resolveJwtUser(jwt);
        User upserted = userDao.upsertUser(user);
        userDao.insertSettings(new UserSettings(upserted.id(), UserTheme.SYSTEM, "de"));
        return upserted;
    }

    public User resolveJwtUser(JsonWebToken jwt) {
        var id = UUID.fromString(jwt.getSubject());

        String ldapEntryDn = jwt.getClaim("distinguished_name");

        var role = UserRole.fromDistinguishedName(ldapEntryDn);

        if (role.isEmpty()) {
            throw new RuntimeException(String.format("User '%s' is no Teacher or Student", id));
        }

        return new User(id, jwt.getClaim("preferred_username"), jwt.getClaim("email"), jwt.getClaim("given_name"),
                jwt.getClaim("family_name"), role.get());
    }

    /**
     * Resolves the User for the current authentication context purely from the JWT and does not persist the resolved
     * user. If the resolved user role does not match the expected role, a UserTypeMismatchException is thrown.
     *
     * @param role
     *            expected user role
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
}

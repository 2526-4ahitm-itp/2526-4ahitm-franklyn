package at.ac.htlleonding.franklynserver.oidc;

import java.util.Optional;
import java.util.UUID;

import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.jwt.JsonWebToken;

import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;

@ApplicationScoped
public class OidcUserService {

    @Inject
    UserDao userDao;

    public User resolveUser(SecurityIdentity identity) {
        var jwt = (JsonWebToken) identity.getPrincipal();

        var ldapEntryDn = jwt.<String>getClaim("ldap_entry_dn");
        var role = UserRole.fromLdapEntryDn(ldapEntryDn)
                .orElseThrow(() -> new AuthenticationFailedException(
                        "Invalid user: missing or unrecognized ldap_entry_dn"));

        var id = UUID.fromString(jwt.getSubject());

        return findExistingUser(id, role)
                .orElseGet(() -> createUser(jwt, id, role));
    }

    private Optional<User> findExistingUser(UUID id, UserRole role) {
        return switch (role) {
            case TEACHER -> userDao.findTeacherById(id).map(u -> u);
            case STUDENT -> userDao.findStudentById(id).map(u -> u);
        };
    }

    private User createUser(JsonWebToken jwt, UUID id, UserRole role) {
        var user = switch (role) {
            case TEACHER -> new Teacher();
            case STUDENT -> new Student();
        };

        user.id = id;
        user.preferredUsername = jwt.getClaim("preferred_username");
        user.email = jwt.getClaim("email");
        user.givenName = jwt.getClaim("given_name");
        user.familyName = jwt.getClaim("family_name");

        return userDao.createTypedUser(user, role.userClass());
    }
}

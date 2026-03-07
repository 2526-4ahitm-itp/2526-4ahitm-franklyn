package at.ac.htlleonding.franklynserver.oidc;

import java.util.Optional;
import java.util.UUID;

import io.quarkus.logging.Log;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.jwt.JsonWebToken;

import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.resource.error.UserTypeMismatch;

@RequestScoped
public class OidcUserService {

    @Inject
    UserDao userDao;

    @Inject
    SecurityIdentity identity;

    // public User resolveUser(SecurityIdentity identity) {
    // var jwt = (JsonWebToken) identity.getPrincipal();
    // String ldapEntryDn = jwt.getClaim("ldap_entry_dn");

    // var role = UserRole.fromLdapEntryDn(ldapEntryDn);

    // if (role.isEmpty()) {
    // throw new RuntimeException("Role is not defined for user");
    // }

    // return resolveUser(identity, role.get().userClass());
    // }

    public <T extends User> T resolveUser(Class<T> clazz) {
        var jwt = (JsonWebToken) identity.getPrincipal();
        var id = UUID.fromString(jwt.getSubject());

        String ldapEntryDn = jwt.getClaim("ldap_entry_dn");

        var role = UserRole.fromLdapEntryDn(ldapEntryDn);

        if (role.isEmpty()) {
            throw new RuntimeException(String.format(
                    "User '%s' is no User or Student",
                    id));
        }

        if (role.get().userClass() != clazz) {
            throw new UserTypeMismatch(clazz, role.get().userClass(), id);
        }

        Log.debugf("Resolving user id=%s, type=%s", id, clazz.getSimpleName());

        return findExistingUser(id, clazz)
                .orElseGet(() -> createUser(jwt, id, clazz));
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

        Log.infof("Auto-provisioning %s '%s' (id=%s, email=%s)",
                clazz.getSimpleName(), user.preferredUsername, id, user.email);
        T created = userDao.createTypedUser(user, clazz);
        Log.infof("Successfully provisioned %s '%s'", clazz.getSimpleName(), user.preferredUsername);
        return created;
    }
}

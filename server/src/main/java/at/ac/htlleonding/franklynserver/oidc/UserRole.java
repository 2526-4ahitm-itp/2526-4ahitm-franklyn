package at.ac.htlleonding.franklynserver.oidc;

import java.util.Optional;

import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;

public enum UserRole {
    TEACHER("teacher", Teacher.class),
    STUDENT("student", Student.class);

    private final String roleName;
    private final Class<? extends User> userClass;

    UserRole(String roleName, Class<? extends User> userClass) {
        this.roleName = roleName;
        this.userClass = userClass;
    }

    public String roleName() {
        return roleName;
    }

    public Class<? extends User> userClass() {
        return userClass;
    }

    public static Optional<UserRole> fromLdapEntryDn(String ldapEntryDn) {
        if (ldapEntryDn == null) {
            return Optional.empty();
        }

        if (ldapEntryDn.contains("OU=Teachers")) {
            return Optional.of(TEACHER);
        }

        if (ldapEntryDn.contains("OU=Students")) {
            return Optional.of(STUDENT);
        }

        return Optional.empty();
    }
}

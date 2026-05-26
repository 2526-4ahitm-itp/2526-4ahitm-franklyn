package at.ac.htlleonding.franklynserver.oidc;

import java.util.Optional;

import at.ac.htlleonding.franklynserver.repository.user.model.Student;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.user.model.User;

public enum UserRole {
    TEACHER("teacher", Teacher.class), STUDENT("student", Student.class), ADMIN("admin", null);

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

    /**
     * Extracts the school class from an LDAP DN, e.g. "OU=4AHITM" → "4AHITM".
     * Returns empty if no class OU is present.
     */
    public static Optional<String> extractClass(String ldapEntryDn) {
        if (ldapEntryDn == null) return Optional.empty();
        for (String part : ldapEntryDn.split(",")) {
            String trimmed = part.trim();
            if (trimmed.startsWith("OU=") && !trimmed.equalsIgnoreCase("OU=Teachers")
                    && !trimmed.equalsIgnoreCase("OU=Students")
                    && !trimmed.equalsIgnoreCase("OU=Admins")) {
                return Optional.of(trimmed.substring(3));
            }
        }
        return Optional.empty();
    }

    public static Optional<UserRole> fromDistinguishedName(String ldapEntryDn) {
        if (ldapEntryDn == null) {
            return Optional.empty();
        }

        if (ldapEntryDn.contains("OU=Admins")) {
            return Optional.of(ADMIN);
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

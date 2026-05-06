package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.Optional;

public enum UserRole {
    TEACHER, 
    STUDENT;

    public static Optional<UserRole> fromDistinguishedName(String ldapEntryDn) {
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

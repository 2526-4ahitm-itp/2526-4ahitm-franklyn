package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.Optional;

public enum UserRole {
    TEACHER(TeacherDetails.class),
    STUDENT(StudentDetails.class);

    public final Class<? extends RoleDetails> roleClass;

    UserRole(Class<? extends RoleDetails> roleClass) {
        this.roleClass = roleClass;
    }

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

package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.UUID;

import io.smallrye.common.constraint.NotNull;

public record TeacherDetails(@NotNull UUID id) implements RoleDetails {
}

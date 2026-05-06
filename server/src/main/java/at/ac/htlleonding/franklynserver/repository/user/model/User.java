package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.UUID;

import io.soabase.recordbuilder.core.RecordBuilder;
import jakarta.annotation.Nullable;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.Ignore;
import org.eclipse.microprofile.graphql.NonNull;

@RecordBuilder
public record User(
        @NotNull UUID id,
        @NotNull String preferredUsername,
        @NotNull String email,
        @Nullable String givenName,
        @Nullable String familyName,
        @NotNull @NonNull  String language,
        @NotNull @NonNull UserTheme theme,
        @NotNull @NonNull UserRole role,
        @Nullable @Ignore RoleDetails details) {
}

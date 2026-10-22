package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.UUID;

import io.soabase.recordbuilder.core.RecordBuilder;
import jakarta.annotation.Nullable;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

@RecordBuilder
public record User(@NotNull @NonNull UUID id,
        @NotNull @NonNull String preferredUsername,
        @NotNull @NonNull String email,
        @Nullable String givenName,
        @Nullable String familyName,
        @NotNull @NonNull UserRole role) {
}

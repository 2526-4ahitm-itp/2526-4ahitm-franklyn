package at.ac.htlleonding.franklynserver.repository.user.model;

import java.util.UUID;

import io.soabase.recordbuilder.core.RecordBuilder;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

@RecordBuilder
public record UserSettings(@NotNull @NonNull UUID userId,
        @NotNull @NonNull UserTheme theme,
        @NotNull @NonNull String language) {
}

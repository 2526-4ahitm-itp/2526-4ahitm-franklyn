package at.ac.htlleonding.franklynserver.resource.setting.model;

import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

public record UserSettingsUpdate (
        @NonNull @NotNull String language,
        @NonNull @NotNull String theme
) {

}

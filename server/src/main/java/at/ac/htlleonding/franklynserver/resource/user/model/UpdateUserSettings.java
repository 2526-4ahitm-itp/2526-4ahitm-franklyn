package at.ac.htlleonding.franklynserver.resource.user.model;

import at.ac.htlleonding.franklynserver.repository.user.model.UserTheme;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

public record UpdateUserSettings(
        @NonNull @NotNull String language,
        @NonNull @NotNull UserTheme theme
) {

}

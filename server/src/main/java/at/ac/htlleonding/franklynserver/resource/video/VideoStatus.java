package at.ac.htlleonding.franklynserver.resource.video;

import org.eclipse.microprofile.graphql.NonNull;

import io.smallrye.graphql.api.Nullable;

public record VideoStatus(
        @NonNull VideoState state,
        @Nullable String link) {
}

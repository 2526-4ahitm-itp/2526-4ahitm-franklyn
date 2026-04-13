package at.ac.htlleonding.franklynserver.repository.notice.model;


import java.time.Instant;
import java.util.UUID;

import org.eclipse.microprofile.graphql.NonNull;

import io.smallrye.graphql.api.Nullable;

public record Notice(
        @NonNull UUID id,
        @NonNull NoticeType type,
        @Nullable Instant startTime,
        @Nullable Instant endTime,
        @NonNull String content) {
}

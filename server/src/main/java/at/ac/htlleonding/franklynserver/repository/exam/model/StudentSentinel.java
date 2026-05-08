package at.ac.htlleonding.franklynserver.repository.exam.model;

import java.util.UUID;

import org.eclipse.microprofile.graphql.NonNull;

public record StudentSentinel(
        @NonNull UUID studentId,
        @NonNull UUID sentinelId) {
}

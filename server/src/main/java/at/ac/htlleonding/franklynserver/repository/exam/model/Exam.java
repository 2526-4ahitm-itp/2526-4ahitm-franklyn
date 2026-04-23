package at.ac.htlleonding.franklynserver.repository.exam.model;

import java.time.Instant;
import java.util.UUID;

import org.eclipse.microprofile.graphql.NonNull;

public record Exam(UUID id,
        @NonNull UUID teacherId,
        @NonNull String title,
        @NonNull Instant startTime,
        @NonNull Instant endTime,
        Instant startedAt,
        Instant endedAt,
        @NonNull Integer pin) {
}

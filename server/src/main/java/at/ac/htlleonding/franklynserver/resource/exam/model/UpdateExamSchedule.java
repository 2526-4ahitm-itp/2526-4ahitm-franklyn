package at.ac.htlleonding.franklynserver.resource.exam.model;

import java.time.Instant;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

public record UpdateExamSchedule(
        @NonNull @NotNull Instant startTime,
        @NonNull @NotNull Instant endTime) {
}

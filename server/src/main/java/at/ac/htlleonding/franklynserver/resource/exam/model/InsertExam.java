package at.ac.htlleonding.franklynserver.resource.exam.model;

import java.time.Instant;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.eclipse.microprofile.graphql.NonNull;

public record InsertExam(
        @NonNull @NotBlank @Size(min = 3, max = 255) String title,
        @NonNull @NotNull Instant startTime,
        @NonNull @NotNull Instant endTime) {
}

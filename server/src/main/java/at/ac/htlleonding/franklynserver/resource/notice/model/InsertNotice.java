package at.ac.htlleonding.franklynserver.resource.notice.model;

import java.time.Instant;

import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.eclipse.microprofile.graphql.NonNull;

public record InsertNotice(
        @NonNull @NotNull NoticeType type,
        Instant startTime,
        Instant endTime,
        @NonNull @NotBlank @Size(min = 3, max = 4096) String content) {
}

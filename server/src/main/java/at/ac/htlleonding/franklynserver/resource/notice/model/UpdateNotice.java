package at.ac.htlleonding.franklynserver.resource.notice.model;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

public record UpdateNotice(Optional<Instant> startTime,
        Optional<Instant> endTime,
        Optional<@NotEmpty List<@NonNull @NotNull @Valid InsertNoticeContent>> contents) {
}

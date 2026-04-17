package at.ac.htlleonding.franklynserver.resource.notice.model;

import java.time.Instant;
import java.util.Optional;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateNotice(
        Optional<Instant> startTime,
        Optional<Instant> endTime,
        Optional<@NotBlank @Size(min = 3, max = 4096) String> content) {
}

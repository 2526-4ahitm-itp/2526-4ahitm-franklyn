package at.ac.htlleonding.franklynserver.resource.notice.model;

import java.time.Instant;
import java.util.Optional;

import jakarta.validation.constraints.Max;

public record UpdateNotice(Optional<Instant> startTime, Optional<Instant> endTime,
        Optional<@Max(4096) String> content) {

}

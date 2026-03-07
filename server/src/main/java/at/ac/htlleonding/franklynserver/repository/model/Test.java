package at.ac.htlleonding.franklynserver.repository.model;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

public record Test(
        UUID id,
        UUID teacherId,
        String title,
        String testAccountPrefix,
        Instant endTime,
        Instant startTime) {
}

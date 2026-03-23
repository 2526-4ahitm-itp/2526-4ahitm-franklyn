package at.ac.htlleonding.franklynserver.repository.test.model;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

public record Test(
        UUID id,
        UUID teacherId,
        String title,
        Instant endTime,
        Instant startTime,
        Integer pin
        ) {
}

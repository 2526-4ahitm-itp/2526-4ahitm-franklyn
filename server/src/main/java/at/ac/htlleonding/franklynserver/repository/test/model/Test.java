package at.ac.htlleonding.franklynserver.repository.test.model;

import java.time.Instant;
import java.util.UUID;

public record Test(UUID id,
        UUID teacherId,
        String title,
        Instant startTime,
        Instant endTime,
        Instant startedAt,
        Instant endedAt,
        Integer pin) {
}

package at.ac.htlleonding.franklynserver.repository.exam.model;

import java.time.Instant;
import java.util.UUID;

public record Exam(UUID id,
        UUID teacherId,
        String title,
        Instant startTime,
        Instant endTime,
        Instant startedAt,
        Instant endedAt,
        Integer pin) {
}

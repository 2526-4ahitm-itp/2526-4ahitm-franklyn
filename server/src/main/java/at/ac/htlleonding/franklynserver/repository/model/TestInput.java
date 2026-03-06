package at.ac.htlleonding.franklynserver.repository.model;

import java.time.Instant;
import java.time.LocalDateTime;

public record TestInput(
        Long teacherId,
        String title,
        String testAccountPrefix,
        LocalDateTime endTime,
        LocalDateTime startTime) {
}

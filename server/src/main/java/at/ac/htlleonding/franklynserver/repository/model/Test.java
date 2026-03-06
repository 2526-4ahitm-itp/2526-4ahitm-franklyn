package at.ac.htlleonding.franklynserver.repository.model;

import java.time.LocalDateTime;

public record Test(
        long id,
        Long teacherId,
        String title,
        String testAccountPrefix,
        LocalDateTime endTime,
        LocalDateTime startTime) {
}

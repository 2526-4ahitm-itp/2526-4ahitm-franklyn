package at.ac.htlleonding.franklynserver.model.graphql;

import java.time.LocalDateTime;
import java.util.UUID;

public record InsertTest(
        UUID teacherId,
        String title,
        LocalDateTime endTime,
        LocalDateTime startTime) {
}

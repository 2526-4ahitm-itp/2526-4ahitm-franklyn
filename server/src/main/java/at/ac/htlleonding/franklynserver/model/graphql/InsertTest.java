package at.ac.htlleonding.franklynserver.model.graphql;

import java.time.LocalDateTime;

public record InsertTest (
        Long teacherId,
        String title,
        String testAccountPrefix,
        LocalDateTime endTime,
        LocalDateTime startTime
){}



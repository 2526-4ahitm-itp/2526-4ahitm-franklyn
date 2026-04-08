package at.ac.htlleonding.franklynserver.resource.exam.model;

import java.time.Instant;

public record UpdateExamSchedule(Instant startTime, Instant endTime) {
}

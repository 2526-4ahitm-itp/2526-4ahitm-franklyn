package at.ac.htlleonding.franklynserver.resource.exam.model;

import java.time.Instant;

public record UpdateExam(String title, Instant startTime, Instant endTime, Instant startedAt, Instant endedAt) {
}

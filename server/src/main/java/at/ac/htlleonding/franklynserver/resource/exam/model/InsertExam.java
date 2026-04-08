package at.ac.htlleonding.franklynserver.resource.exam.model;

import java.time.Instant;

public record InsertExam(String title, Instant startTime, Instant endTime) {
}

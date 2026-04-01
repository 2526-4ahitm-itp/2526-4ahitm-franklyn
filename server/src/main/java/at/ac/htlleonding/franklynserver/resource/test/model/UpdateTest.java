package at.ac.htlleonding.franklynserver.resource.test.model;

import java.time.Instant;

public record UpdateTest(String title, Instant startTime, Instant endTime, Instant startedAt, Instant endedAt) {
}

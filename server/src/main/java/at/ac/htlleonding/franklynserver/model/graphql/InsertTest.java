package at.ac.htlleonding.franklynserver.model.graphql;

import java.time.Instant;
import java.util.UUID;

public record InsertTest(UUID teacherId, String title, Instant endTime, Instant startTime) {
}

package at.ac.htlleonding.franklynserver.repository.test.model;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

import org.eclipse.microprofile.graphql.Input;

@Input("TestInput")
public record TestInput(
        UUID teacherId,
        String title,
        Instant endTime,
        Instant startTime) {
}

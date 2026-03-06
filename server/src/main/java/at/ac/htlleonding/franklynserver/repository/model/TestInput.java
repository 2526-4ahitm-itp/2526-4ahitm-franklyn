package at.ac.htlleonding.franklynserver.repository.model;

import java.time.Instant;
import java.time.LocalDateTime;

import org.eclipse.microprofile.graphql.Input;

@Input("TestInput")
public record TestInput(
        Long teacherId,
        String testAccountPrefix,
        String title,
        Instant endTime,
        Instant startTime) {
}

package at.ac.htlleonding.franklynserver.repository.test.model;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.eclipse.microprofile.graphql.Input;

@Input("TestInput")
public record TestInput(
        String title,
        Optional<Instant> endTime,
        Optional<Instant> startTime) {
}

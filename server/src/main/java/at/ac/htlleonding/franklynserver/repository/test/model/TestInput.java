package at.ac.htlleonding.franklynserver.repository.test.model;

import java.time.Instant;

import org.eclipse.microprofile.graphql.Input;

@Input("TestInput")
public record TestInput(String title, Instant endTime, Instant startTime) {
}

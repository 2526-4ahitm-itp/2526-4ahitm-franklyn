package at.ac.htlleonding.franklynserver.resource.error;

import java.time.Instant;

import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("start-not-before-end")
public class StartCannotBeBeforeEndException extends GraphQLBusinessException {
    public StartCannotBeBeforeEndException(Instant start, Instant end) {
        super(String.format("Start '%s' cannot be before end '%s'.", start, end));
    }
}

package at.ac.htlleonding.franklynserver.resource.error;

import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.User;
import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("user-type-mismatch")
public class UserTypeMismatch extends RuntimeException {
    public UserTypeMismatch(
            Class<? extends User> expected,
            Class<? extends User> actual,
            UUID id) {
        super(String.format(
                "Expected to resolve '%s' but got '%s' with id '%s'",
                expected.getSimpleName(),
                actual.getSimpleName(),
                id));
    }

}

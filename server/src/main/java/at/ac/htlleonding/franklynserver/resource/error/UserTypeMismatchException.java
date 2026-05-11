package at.ac.htlleonding.franklynserver.resource.error;

import java.util.UUID;

import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("user-type-mismatch")
public class UserTypeMismatchException extends GraphQLBusinessException {
    public UserTypeMismatchException(UserRole expected, UserRole actual, UUID id) {
        super(String.format("Expected to resolve '%s' but got '%s' with id '%s'", expected, actual, id));
    }

}

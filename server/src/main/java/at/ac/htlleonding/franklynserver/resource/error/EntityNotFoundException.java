package at.ac.htlleonding.franklynserver.resource.error;

import java.util.UUID;

import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("entity-not-found")
public class EntityNotFoundException extends GraphQLBusinessException {
    public EntityNotFoundException(Class c, UUID id) {
        super(String.format("Entity of type '%s' with id '%s' not found!", c.getSimpleName(), id));
    }
}

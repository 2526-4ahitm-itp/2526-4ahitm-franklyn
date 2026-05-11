package at.ac.htlleonding.franklynserver.repository.user.model;

import org.eclipse.microprofile.graphql.Interface;
import org.eclipse.microprofile.graphql.Name;

import java.util.UUID;

@Interface
public interface RoleDetails {
    @Name("id")
    UUID id();
}

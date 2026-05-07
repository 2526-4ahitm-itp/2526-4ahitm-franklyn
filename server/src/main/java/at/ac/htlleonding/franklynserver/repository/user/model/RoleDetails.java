package at.ac.htlleonding.franklynserver.repository.user.model;

import jakarta.json.bind.annotation.JsonbSubtype;
import jakarta.json.bind.annotation.JsonbTypeInfo;
import org.eclipse.microprofile.graphql.Interface;
import org.eclipse.microprofile.graphql.Name;

import java.util.UUID;

@Interface
public interface RoleDetails {
    @Name("id")
    UUID id();
}

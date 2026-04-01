package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("register")
public class RegistrationService {

    @Inject
    OidcUserService userService;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public User registerUser() throws GraphQLBusinessException {
        return userService.resolveUser();
    }
}

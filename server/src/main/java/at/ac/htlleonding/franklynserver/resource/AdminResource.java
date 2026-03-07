package at.ac.htlleonding.franklynserver.resource;

import org.eclipse.microprofile.jwt.JsonWebToken;

import io.quarkus.security.identity.SecurityIdentity;
import jakarta.inject.Inject;
import jakarta.annotation.security.RolesAllowed;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/test")
public class AdminResource {

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @RolesAllowed("admin")
    public String hello() {
        return "Access for subjectis granted";
    }
}
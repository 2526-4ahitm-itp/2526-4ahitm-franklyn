
import io.quarkus.security.identity.SecurityIdentity
import jakarta.inject.Inject
import jakarta.ws.rs.GET
import jakarta.ws.rs.Path
import jakarta.ws.rs.Produces
import jakarta.ws.rs.core.MediaType
import jakarta.ws.rs.core.Response
import org.jboss.resteasy.reactive.NoCache


@Path("teacher")
class TeacherResource {

    @Inject
    lateinit var identity: SecurityIdentity

    @GET
    @Path("me")
    @Produces(MediaType.APPLICATION_JSON)
    @NoCache
    fun me(): Response = Response.ok(Teacher(identity)).build()
}

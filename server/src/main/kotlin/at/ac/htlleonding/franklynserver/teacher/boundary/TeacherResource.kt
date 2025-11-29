
import jakarta.ws.rs.Path
import jakarta.ws.rs.core.Response
import jakarta.ws.rs.core.MediaType
import jakarta.ws.rs.GET
import jakarta.ws.rs.QueryParam
import jakarta.ws.rs.Produces
import jakarta.ws.rs.POST
import jakarta.transaction.Transactional
import jakarta.inject.Inject
import io.quarkus.security.identity.SecurityIdentity
import io.quarkus.security.Authenticated
import org.jboss.resteasy.reactive.NoCache


@Path("teacher")
class TeacherResource {

    @Inject
    lateinit var identity: SecurityIdentity
    
    @GET
    @Path("me")
    @Produces(MediaType.APPLICATION_JSON)
    @NoCache
    fun me(): Response {
        return Response.ok(Teacher(identity)).build()
    }

}

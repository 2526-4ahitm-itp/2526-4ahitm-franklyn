import at.ac.htlleonding.franklyn.teacher.entity.Teacher
import io.quarkus.security.identity.SecurityIdentity
import jakarta.inject.Inject
import jakarta.transaction.Transactional
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
    @Transactional
    @NoCache
    fun me(): Response = Response.ok(Teacher.findOrCreateTeacherInAuthContext(identity)).build()
}

package at.ac.htlleonding.franklyn.test.boundary

import Teacher
import at.ac.htlleonding.franklyn.test.entity.Test
import at.ac.htlleonding.franklyn.test.entity.dto.CreateTestDTO
import at.ac.htlleonding.franklyn.test.mapper.TestDTOMapper
import io.quarkus.security.identity.SecurityIdentity
import jakarta.inject.Inject
import jakarta.transaction.Transactional
import jakarta.ws.rs.GET
import jakarta.ws.rs.POST
import jakarta.ws.rs.Path
import jakarta.ws.rs.Produces
import jakarta.ws.rs.core.MediaType
import jakarta.ws.rs.core.Response
import jakarta.ws.rs.core.UriInfo

@Path("test")
class TestResource {

    @Inject
    lateinit var identity: SecurityIdentity
    
    @Inject
    lateinit var uriInfo: UriInfo


    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    fun getTestsOfTeacher(): Response {
        val teacher = Teacher.findOrCreateTeacherInAuthContext(identity)
        return Response.ok(Test.findByTeacher(teacher)).build()
    }

    @POST
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    fun createTestForTeacher(test: CreateTestDTO): Response {
        val teacher = Teacher.findOrCreateTeacherInAuthContext(identity)

        val test: Test = TestDTOMapper.fromDTO(test)

        test.teacher = teacher

        test.persist()

        return Response.created(
            uriInfo.absolutePathBuilder.path(
                test.id.toString()
            ).build()
        )
            .entity(test).build()
    }

}

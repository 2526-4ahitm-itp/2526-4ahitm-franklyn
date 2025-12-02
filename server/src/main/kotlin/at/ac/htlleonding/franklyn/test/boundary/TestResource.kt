package at.ac.htlleonding.franklyn.test.boundary

import Teacher
import at.ac.htlleonding.franklyn.test.entity.Test
import at.ac.htlleonding.franklyn.test.entity.dto.CreateTestDTO
import at.ac.htlleonding.franklyn.test.entity.dto.PatchTestDTO
import at.ac.htlleonding.franklyn.test.mapper.TestDTOMapper
import io.quarkus.security.identity.SecurityIdentity
import jakarta.inject.Inject
import jakarta.transaction.Transactional
import jakarta.ws.rs.GET
import jakarta.ws.rs.PATCH
import jakarta.ws.rs.POST
import jakarta.ws.rs.Path
import jakarta.ws.rs.PathParam
import jakarta.ws.rs.Produces
import jakarta.ws.rs.core.MediaType
import jakarta.ws.rs.core.Response
import jakarta.ws.rs.core.UriInfo
import java.time.LocalDateTime

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

    @PATCH
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    fun patchTestForTeacher(patchTest: PatchTestDTO): Response {
        val teacher = Teacher.findOrCreateTeacherInAuthContext(identity)
        
        val test: Test? = Test.find("id", patchTest.id).firstResult()

        if (test == null) {
            return Response.status(404).build()
        }

        patchTest.title?.let { test.title = it }
        patchTest.testAccountPrefix?.let { test.testAccountPrefix = it }
        patchTest.startTime?.let { test.startTime = it }
        patchTest.endTime?.let { test.endTime = it }
        
        test.persist()
        
        return Response.noContent().build()
    }

    @GET
    @Path("{testId}")
    @Produces(MediaType.APPLICATION_JSON)
    fun getTestById(@PathParam("testId") testId: String): Response {

        val test: Test? = Test.find("id", testId).firstResult()

        if (test == null) {
            return Response.status(404).build()
        } else {
            return Response.ok(test).build()
        }
    }

}

package at.ac.htlleonding.franklynserver.resource.video;

import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;

import java.io.File;
import java.util.UUID;

@Path("/videos")
@ApplicationScoped
@RolesAllowed({"teacher", "franklyn-admin"})
public class VideoRestResource {

    @Inject
    ExamSessionDao examSessionDao;

    @Inject
    FranklynConfig config;

    @GET
    @Path("/{sentinelId}.mp4")
    @Produces("video/mp4")
    public Response getVideo(@PathParam("sentinelId") UUID sentinelId) {
        ExamSession session = examSessionDao.findBySentinelId(sentinelId)
                .orElseThrow(() -> new NotFoundException("No session found for sentinel " + sentinelId));

        if (!"DONE".equals(session.videoStatus()) || session.videoFilePath() == null) {
            return Response.status(Response.Status.NOT_FOUND)
                    .entity("Video not ready")
                    .build();
        }

        File file = new File(session.videoFilePath());
        if (!file.exists()) {
            return Response.status(Response.Status.NOT_FOUND)
                    .entity("Video file not found on disk")
                    .build();
        }

        return Response.ok(file, "video/mp4").build();
    }
}

package at.ac.htlleonding.franklynserver.resource.video;

import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import at.ac.htlleonding.franklynserver.resource.error.EntityNotFoundException;
import at.ac.htlleonding.franklynserver.service.VideoService;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.NonNull;
import org.eclipse.microprofile.graphql.Query;

import java.util.UUID;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({"teacher", "franklyn-admin"})
public class VideoResource {

    @Inject
    VideoService videoService;

    @Inject
    ExamSessionDao examSessionDao;

    @Mutation
    public void generateSentinelVideo(@NonNull UUID sentinelId) throws EntityNotFoundException {
        examSessionDao.findBySentinelId(sentinelId)
                .orElseThrow(() -> new EntityNotFoundException(ExamSession.class, sentinelId));
        videoService.scheduleVideoGeneration(sentinelId);
    }

    @Query
    public @NonNull VideoStatus videoStatus(@NonNull UUID sentinelId) throws EntityNotFoundException {
        ExamSession session = examSessionDao.findBySentinelId(sentinelId)
                .orElseThrow(() -> new EntityNotFoundException(ExamSession.class, sentinelId));

        if ("DONE".equals(session.videoStatus()) && session.videoFilePath() != null) {
            return new VideoStatus(VideoState.DONE, "/api/videos/" + sentinelId + ".mp4");
        }
        return new VideoStatus(VideoState.PENDING, null);
    }
}

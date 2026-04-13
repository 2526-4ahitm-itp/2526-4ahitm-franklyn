package at.ac.htlleonding.franklynserver.resource.notice;

import java.util.List;
import java.util.UUID;

import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.NonNull;
import org.eclipse.microprofile.graphql.Query;

import at.ac.htlleonding.franklynserver.repository.notice.NoticeDao;
import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.resource.error.EntityNotFoundException;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.notice.model.InsertNotice;
import at.ac.htlleonding.franklynserver.resource.notice.model.UpdateNotice;
import io.smallrye.graphql.api.Subscription;
import io.smallrye.mutiny.Multi;
import io.smallrye.mutiny.operators.multi.processors.BroadcastProcessor;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.validation.Valid;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({"teacher"})
public class NoticeResource {

    @Inject
    NoticeDao noticeDao;

    private final BroadcastProcessor<Notice> processor = BroadcastProcessor.create();

    @Query
    public List<Notice> notices() {
        return noticeDao.findAll();
    }

    @Subscription
    public Multi<Notice> noticesSub() {
        return processor.toHotStream();
    }

    @RolesAllowed("franklyn-admin")
    @Mutation
    public @NonNull Notice createNotice(@Valid @NonNull InsertNotice insertNotice) {
        var notice = noticeDao.insert(
                insertNotice.type(),
                insertNotice.content(),
                insertNotice.startTime(),
                insertNotice.endTime()
        );
        processor.onNext(notice);
        return notice;
    }

    @RolesAllowed("franklyn-admin")
    @Mutation
    public @NonNull Notice updateNotice(
            @NonNull UUID id, @Valid @NonNull UpdateNotice updateNotice) throws GraphQLBusinessException {
        Notice notice = noticeDao.findById(id)
                .orElseThrow(() -> new EntityNotFoundException(Notice.class, id));

        var updatedNotice = noticeDao.update(
                notice.id(),
                updateNotice.content().orElse(notice.content()),
                updateNotice.startTime().orElse(notice.startTime()),
                updateNotice.endTime().orElse(notice.endTime())
        ).orElseThrow(() -> new EntityNotFoundException(Notice.class, id));

        processor.onNext(updatedNotice);

        return updatedNotice;
    }
}

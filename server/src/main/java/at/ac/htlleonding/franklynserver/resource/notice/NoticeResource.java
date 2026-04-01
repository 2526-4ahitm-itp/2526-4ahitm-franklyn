package at.ac.htlleonding.franklynserver.resource.notice;

import java.util.List;

import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.Query;

import at.ac.htlleonding.franklynserver.repository.notice.NoticeDao;
import at.ac.htlleonding.franklynserver.repository.notice.model.Notice;
import at.ac.htlleonding.franklynserver.resource.notice.model.InsertNotice;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({"teacher"})
public class NoticeResource {

    @Inject
    NoticeDao noticeDao;

    @Query
    public List<Notice> notices() {
        return noticeDao.findAll();
    }

    @Mutation
    public Notice createNotice(InsertNotice insertNotice) {
        return noticeDao.insert(insertNotice.type(), insertNotice.content(), insertNotice.startTime(), insertNotice.endTime());
    }

}

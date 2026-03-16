package at.ac.htlleonding.franklynserver.repository.notice;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Produces;
import org.jdbi.v3.core.Jdbi;

@ApplicationScoped
public class NoticeDaoProducer {

    @Inject
    Jdbi jdbi;

    @ApplicationScoped
    @Produces
    NoticeDao produceNoticeDao() {
        return jdbi.onDemand(NoticeDao.class);
    }
}

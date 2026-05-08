package at.ac.htlleonding.franklynserver.repository.exam;

import org.jdbi.v3.core.Jdbi;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;

@ApplicationScoped
public class ExamSessionDaoProducer {

    @Inject
    Jdbi jdbi;

    @ApplicationScoped
    @Produces
    ExamSessionDao produceExamSessionDao() {
        return jdbi.onDemand(ExamSessionDao.class);
    }
}

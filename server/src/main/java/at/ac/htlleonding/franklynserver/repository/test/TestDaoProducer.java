package at.ac.htlleonding.franklynserver.repository.test;

import org.jdbi.v3.core.Jdbi;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;

@ApplicationScoped
public class TestDaoProducer {

    @Inject
    Jdbi jdbi;

    @ApplicationScoped
    @Produces
    TestDao producTestDao() {
        return jdbi.onDemand(TestDao.class);
    }
}

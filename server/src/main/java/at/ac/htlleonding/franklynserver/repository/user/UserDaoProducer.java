package at.ac.htlleonding.franklynserver.repository.user;

import org.jdbi.v3.core.Jdbi;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;

@ApplicationScoped
public class UserDaoProducer {

    @Inject
    Jdbi jdbi;

    @ApplicationScoped
    @Produces
    UserDao produceUserDao() {
        return jdbi.onDemand(UserDao.class);
    }

}

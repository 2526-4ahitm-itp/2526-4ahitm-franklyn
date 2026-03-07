package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.test.TestDao;
import at.ac.htlleonding.franklynserver.repository.test.model.Test;
import at.ac.htlleonding.franklynserver.repository.test.model.TestInput;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.Name;
import org.eclipse.microprofile.graphql.Query;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@GraphQLApi
@ApplicationScoped
public class TestResource {

    @Inject
    Jdbi jdbi;

    @Query
    public List<Test> tests() {
        return jdbi.withExtension(TestDao.class, TestDao::findAll);
    }

    @Query
    public Optional<Test> testId(@Name("id") UUID id) {
        return jdbi.withExtension(TestDao.class, dao -> dao.findById(id));
    }

    @Mutation
    public Test createTest(TestInput test) {
        return jdbi.withExtension(TestDao.class, dao -> dao.insert(
                test.teacherId(),
                test.title(),
                test.testAccountPrefix(),
                test.endTime(),
                test.startTime()));
    }

    @Mutation
    public Optional<Test> updateTest(UUID id, TestInput test) {
        return jdbi.withExtension(TestDao.class, dao -> dao.update(
                id,
                test.title(),
                test.testAccountPrefix(),
                test.endTime(),
                test.startTime()));
    }

    @Mutation
    public Optional<Test> deleteTest(UUID id) {
        return jdbi.withExtension(TestDao.class, dao -> dao.delete(id));
    }

}

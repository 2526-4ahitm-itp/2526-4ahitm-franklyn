package at.ac.htlleonding.franklynserver.resource;

<<<<<<<HEAD

import at.ac.htlleonding.franklynserver.model.graphql.InsertTest;
import at.ac.htlleonding.franklynserver.repository.TestQueries;
import io.agroal.api.AgroalDataSource;=======
import at.ac.htlleonding.franklynserver.repository.TestDao;
import at.ac.htlleonding.franklynserver.repository.model.Test;>>>>>>>a66f3b0(WIP:adding jdbi opencode)
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.Name;
import org.eclipse.microprofile.graphql.Query;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Optional;

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
    public Optional<Test> testId(@Name("id") long id) {
        return jdbi.withExtension(TestDao.class, dao -> dao.findById(id));
    }

    @Mutation
    public Test createTest(Test test) {
        return jdbi.withExtension(TestDao.class, dao -> dao.insert(
                test.teacherId(),
                test.title(),
                test.testAccountPrefix(),
                test.endTime(),
                test.startTime()));
    }

    @Mutation
    public Optional<Test> updateTest(long id, Test test) {
        return jdbi.withExtension(TestDao.class, dao -> dao.update(
                id,
                test.title(),
                test.testAccountPrefix(),
                test.endTime(),
                test.startTime()));
    }

    @Mutation
    public Optional<Test> deleteTest(long id) {
        return jdbi.withExtension(TestDao.class, dao -> dao.delete(id));
    }
}

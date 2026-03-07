package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.test.TestDao;
import at.ac.htlleonding.franklynserver.repository.test.model.Test;
import at.ac.htlleonding.franklynserver.repository.test.model.TestInput;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import io.quarkus.security.Authenticated;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.annotation.security.RolesAllowed;
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
@Authenticated
public class TestResource {

    @Inject
    Jdbi jdbi;

    @Inject
    TestDao testDao;

    @Inject
    SecurityIdentity identity;

    @Query
    @RolesAllowed("teacher")
    public List<Test> tests() {
        System.out.println(identity.getPrincipal());
        return testDao.findAll();
    }

    @Query
    public Optional<Test> testId(@Name("id") UUID id) {
        return jdbi.withExtension(TestDao.class, dao -> dao.findById(id));
    }

    @Mutation
    public Test createTest(TestInput test) {
        return testDao.insert(test.teacherId(),
                test.title(),
                test.endTime(),
                test.startTime());
    }

    @Mutation
    public Optional<Test> updateTest(UUID id, TestInput test) {
        return testDao.update(
                id,
                test.title(),
                test.endTime(),
                test.startTime());
    }

    @Mutation
    public void deleteTest(UUID id) {
        testDao.delete(id);
    }

}

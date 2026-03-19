package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
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
@RolesAllowed({"teacher", "franklyn-admin"})
public class TestResource {

    @Inject
    Jdbi jdbi;

    @Inject
    TestDao testDao;

    @Inject
    OidcUserService userService;

    @Inject
    SecurityIdentity identity;

    @Query
    public List<Test> tests() {
        return testDao.findAll();
    }

    @Query
    public Optional<Test> testId(@Name("id") UUID id) {
        return testDao.findById(id);
    }

    @Mutation
    public Test createTest(TestInput test) {

        Teacher t = userService.resolveUser(Teacher.class);

        return testDao.insert(
                t.id,
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

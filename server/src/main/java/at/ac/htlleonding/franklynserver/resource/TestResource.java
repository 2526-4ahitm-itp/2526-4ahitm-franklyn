package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.test.TestDao;
import at.ac.htlleonding.franklynserver.repository.test.model.Test;
import at.ac.htlleonding.franklynserver.repository.test.model.TestInput;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import io.quarkus.logging.Log;
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
import java.util.Random;
import java.util.UUID;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({"teacher", "franklyn-admin"})
public class TestResource {

    @Inject
    FranklynConfig config;
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
        Teacher t = userService.resolveUser(Teacher.class);
        Log.infof("Fetching tests for teacher id=%s, username=%s", t.id, t.preferredUsername);
        List<Test> result = testDao.findByTeacherId(t.id);
        Log.infof("Found %d tests for teacher %s", result.size(), t.id);
        return result;
    }

    @Query
    public Optional<Test> testId(@Name("id") UUID id) {
        return testDao.findById(id);
    }

    @Query
    public Optional<Test> testPin(@Name("pin") int pin) {
        return testDao.findByPin(pin);
    }

    @Mutation
    public Test createTest(TestInput test) {
        Teacher t = userService.resolveUser(Teacher.class);
        Log.infof("Creating test for teacher id=%s, username=%s, title=%s", t.id, t.preferredUsername, test.title());
        Random rnd = new Random();
        List<Integer> pinList = testDao.findAll().stream().map(Test::pin).toList();
        int pin = rnd.nextInt(config.pin().min(), config.pin().max() + 1);
        while (pinList.contains(pin)) {
            pin = rnd.nextInt(config.pin().min(), config.pin().max() + 1);
        }
        Test created = testDao.insert(
                t.id,
                test.title(),
                test.endTime(),
                test.startTime(),
                pin
                );
        Log.infof("Created test id=%s, teacherId=%s, title=%s", created.id(), created.teacherId(), created.title());
        return created;
    }

    @Mutation
    public Optional<Test> updateTest(UUID id, TestInput test) {
        Log.infof("Updating test id=%s, title=%s, startTime=%s, endTime=%s", id, test.title(), test.startTime(), test.endTime());
        Optional<Test> updated = testDao.update(
                id,
                test.title(),
                test.endTime(),
                test.startTime());
        updated.ifPresent(t -> Log.infof("Updated test id=%s, startTime=%s, endTime=%s", t.id(), t.startTime(), t.endTime()));
        return updated;
    }

    @Mutation
    public void deleteTest(UUID id) {
        Log.infof("Deleting test id=%s", id);
        testDao.delete(id);
    }

}

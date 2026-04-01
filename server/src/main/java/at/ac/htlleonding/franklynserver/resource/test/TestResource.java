package at.ac.htlleonding.franklynserver.resource.test;

import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.test.TestDao;
import at.ac.htlleonding.franklynserver.repository.test.model.Test;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.resource.error.exam.ExamAlreadyStartedException;
import at.ac.htlleonding.franklynserver.resource.error.EntityNotFoundException;
import at.ac.htlleonding.franklynserver.resource.error.StartCannotBeBeforeEndException;
import at.ac.htlleonding.franklynserver.resource.error.exam.ExamAlreadyEndedException;
import at.ac.htlleonding.franklynserver.resource.error.exam.ExamNotStartedYetException;
import at.ac.htlleonding.franklynserver.resource.test.model.InsertTest;
import at.ac.htlleonding.franklynserver.resource.test.model.UpdateTest;
import at.ac.htlleonding.franklynserver.resource.test.model.UpdateTestSchedule;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.GraphQLException;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.Query;
import org.jdbi.v3.core.Jdbi;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import java.util.UUID;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({ "teacher", "franklyn-admin" })
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
        return testDao.findByTeacher(userService.resolveJwtUser(Teacher.class).id);
    }

    @Query
    public Optional<Test> testId(UUID id) {
        return testDao.findById(id);
    }

    @Query
    public Optional<Test> testPin(int pin) {
        return testDao.findByPin(pin);
    }

    @Mutation
    public Test createTest(InsertTest testInput) {

        if (testInput.endTime().isBefore(testInput.startTime())) {
            throw new StartCannotBeBeforeEndException(testInput.startTime(), testInput.endTime());
        }

        Teacher t = userService.resolveUser(Teacher.class);
        Random rnd = new Random();
        List<Integer> pinList = tests().stream().map(Test::pin).toList();
        int pin = rnd.nextInt(config.pin().min(), config.pin().max() + 1);
        while (pinList.contains(pin)) {
            pin = rnd.nextInt(config.pin().min(), config.pin().max() + 1);
        }
        return testDao.insert(t.id, testInput.title(), testInput.startTime(), testInput.endTime(), pin);
    }

    @Mutation
    public Test startTest(UUID testId) {
        Teacher t = userService.resolveJwtUser(Teacher.class);

        var optTest = testDao.findByIdAndTeacherId(testId, t.id);

        Test test = optTest.orElseThrow(() -> new EntityNotFoundException(Test.class, testId));

        if (test.startedAt() != null) {
            throw new ExamAlreadyStartedException(testId);
        }

        var updatedTest = testDao.update(testId, test.title(), test.teacherId(), test.startTime(), test.endTime(),
                Instant.now(), null);

        return updatedTest.get();
    }

    @Mutation
    public Test endTest(UUID testId) {
        Teacher t = userService.resolveJwtUser(Teacher.class);

        var optTest = testDao.findByIdAndTeacherId(testId, t.id);

        Test test = optTest.orElseThrow(() -> new EntityNotFoundException(Test.class, testId));

        if (test.endedAt() != null) {
            throw new ExamAlreadyEndedException(testId);
        }

        if (test.startedAt() == null) {
            throw new ExamNotStartedYetException(testId);
        }

        var updatedTest = testDao.update(testId, test.title(), test.teacherId(), test.startTime(), test.endTime(),
                test.startedAt(), Instant.now());

        return updatedTest.get();
    }

    @Mutation
    public Test updateTestSchedule(UUID testId, UpdateTestSchedule testScheduleInput) {

        if (testScheduleInput.endTime().isBefore(testScheduleInput.startTime())) {
            throw new StartCannotBeBeforeEndException(testScheduleInput.startTime(), testScheduleInput.endTime());
        }

        var optTest = testDao.updateSchedule(testId, testScheduleInput.startTime(),
                testScheduleInput.endTime());

        return optTest.orElseThrow(() -> new EntityNotFoundException(Test.class, testId));
    }

    @Mutation
    public void deleteTest(UUID id) {
        testDao.delete(id, userService.resolveJwtUser(Teacher.class).id);
    }
}

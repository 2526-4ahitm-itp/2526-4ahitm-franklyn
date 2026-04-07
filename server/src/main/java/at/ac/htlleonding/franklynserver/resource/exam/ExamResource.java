package at.ac.htlleonding.franklynserver.resource.exam;

import at.ac.htlleonding.franklynserver.config.FranklynConfig;
import at.ac.htlleonding.franklynserver.oidc.OidcUserService;
import at.ac.htlleonding.franklynserver.repository.exam.ExamDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.Exam;
import at.ac.htlleonding.franklynserver.repository.user.model.Teacher;
import at.ac.htlleonding.franklynserver.resource.error.exam.ExamAlreadyStartedException;
import at.ac.htlleonding.franklynserver.resource.error.EntityNotFoundException;
import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import at.ac.htlleonding.franklynserver.resource.error.StartCannotBeBeforeEndException;
import at.ac.htlleonding.franklynserver.resource.error.exam.ExamAlreadyEndedException;
import at.ac.htlleonding.franklynserver.resource.error.exam.ExamNotStartedYetException;
import at.ac.htlleonding.franklynserver.resource.exam.model.InsertExam;
import at.ac.htlleonding.franklynserver.resource.exam.model.UpdateExamSchedule;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
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
public class ExamResource {

    @Inject
    FranklynConfig config;
    @Inject
    Jdbi jdbi;

    @Inject
    ExamDao examDao;

    @Inject
    OidcUserService userService;

    @Inject
    SecurityIdentity identity;

    @Query
    public List<Exam> exams() throws GraphQLBusinessException {
        return examDao.findByTeacher(userService.resolveJwtUser(Teacher.class).id);
    }

    @Query
    public Optional<Exam> examId(UUID id) {
        return examDao.findById(id);
    }

    @Query
    public Optional<Exam> examPin(int pin) {
        return examDao.findByPin(pin);
    }

    @Mutation
    public Exam createExam(InsertExam examInput) throws GraphQLBusinessException {

        if (examInput.endTime().isBefore(examInput.startTime())) {
            throw new StartCannotBeBeforeEndException(examInput.startTime(), examInput.endTime());
        }

        Teacher teacher = userService.resolveUser(Teacher.class);
        Random rnd = new Random();
        List<Integer> pinList = exams().stream().map(Exam::pin).toList();
        int pin = rnd.nextInt(config.pin().min(), config.pin().max() + 1);
        while (pinList.contains(pin)) {
            pin = rnd.nextInt(config.pin().min(), config.pin().max() + 1);
        }
        return examDao.insert(teacher.id, examInput.title(), examInput.startTime(), examInput.endTime(), pin);
    }

    @Mutation
    public Exam startExam(UUID examId) throws GraphQLBusinessException {
        Teacher t = userService.resolveJwtUser(Teacher.class);

        var optExam = examDao.findByIdAndTeacherId(examId, t.id);

        Exam exam = optExam.orElseThrow(() -> new EntityNotFoundException(Exam.class, examId));

        if (exam.startedAt() != null) {
            throw new ExamAlreadyStartedException(examId);
        }

        var updatedExam = examDao.update(examId, exam.title(), exam.teacherId(), exam.startTime(), exam.endTime(),
                Instant.now(), null);

        return updatedExam.get();
    }

    @Mutation
    public Exam endExam(UUID examId) throws GraphQLBusinessException {
        Teacher t = userService.resolveJwtUser(Teacher.class);

        var optExam = examDao.findByIdAndTeacherId(examId, t.id);

        Exam exam = optExam.orElseThrow(() -> new EntityNotFoundException(Exam.class, examId));

        if (exam.endedAt() != null) {
            throw new ExamAlreadyEndedException(examId);
        }

        if (exam.startedAt() == null) {
            throw new ExamNotStartedYetException(examId);
        }

        var updatedExam = examDao.update(examId, exam.title(), exam.teacherId(), exam.startTime(), exam.endTime(),
                exam.startedAt(), Instant.now());

        return updatedExam.get();
    }

    @Mutation
    public Exam updateExamSchedule(UUID examId, UpdateExamSchedule examScheduleInput) throws GraphQLBusinessException {

        if (examScheduleInput.endTime().isBefore(examScheduleInput.startTime())) {
            throw new StartCannotBeBeforeEndException(examScheduleInput.startTime(), examScheduleInput.endTime());
        }

        var optExam = examDao.updateSchedule(examId, examScheduleInput.startTime(),
                examScheduleInput.endTime());

        return optExam.orElseThrow(() -> new EntityNotFoundException(Exam.class, examId));
    }

    @Mutation
    public void deleteExam(UUID id) throws GraphQLBusinessException {
        examDao.delete(id, userService.resolveJwtUser(Teacher.class).id);
    }
}

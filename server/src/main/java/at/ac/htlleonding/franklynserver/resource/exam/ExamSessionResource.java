package at.ac.htlleonding.franklynserver.resource.exam;

import java.util.List;
import java.util.UUID;

import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.NonNull;
import org.eclipse.microprofile.graphql.Query;
import org.eclipse.microprofile.graphql.Source;

import at.ac.htlleonding.franklynserver.resource.error.EntityNotFoundException;
import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({"teacher", "franklyn-admin"})
public class ExamSessionResource {

    @Inject
    ExamSessionDao examSessionDao;

    @Inject
    UserDao userDao;

    @Query
    public @NonNull List<ExamSession> allStudents(@NonNull UUID examId) {
        return examSessionDao.findByExamId(examId);
    }

    public @NonNull User student(@Source ExamSession session) throws EntityNotFoundException {
        return userDao.findById(session.studentId())
                .orElseThrow(() -> new EntityNotFoundException(User.class, session.studentId()));
    }
}

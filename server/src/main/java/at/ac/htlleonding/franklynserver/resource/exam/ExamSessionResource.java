package at.ac.htlleonding.franklynserver.resource.exam;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.NonNull;
import org.eclipse.microprofile.graphql.Query;
import org.eclipse.microprofile.graphql.Source;

import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import at.ac.htlleonding.franklynserver.repository.user.UserDao;
import at.ac.htlleonding.franklynserver.repository.user.model.User;
import at.ac.htlleonding.franklynserver.repository.user.model.UserRole;
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

    public Optional<User> student(@Source ExamSession session) {
        return userDao.findByIdAndType(session.studentId(), UserRole.STUDENT);
    }
}

package at.ac.htlleonding.franklynserver.resource.exam;

import java.util.List;
import java.util.UUID;

import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.NonNull;
import org.eclipse.microprofile.graphql.Query;

import at.ac.htlleonding.franklynserver.repository.exam.ExamSessionDao;
import at.ac.htlleonding.franklynserver.repository.exam.model.ExamSession;
import jakarta.annotation.security.RolesAllowed;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@GraphQLApi
@ApplicationScoped
@RolesAllowed({"teacher", "franklyn-admin"})
public class ExamSessionResource {

    @Inject
    ExamSessionDao examSessionDao;

    @Query
    public @NonNull List<ExamSession> allStudents(@NonNull UUID examId) {
        return examSessionDao.findByExamId(examId);
    }
}

package at.ac.htlleonding.franklynserver.resource.error.exam;

import java.util.UUID;

import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("exam-already-ended")
public class ExamAlreadyEndedException extends GraphQLBusinessException {
    public ExamAlreadyEndedException(UUID examId) {
        super(String.format("Exam '%s' already ended", examId));
    }
}

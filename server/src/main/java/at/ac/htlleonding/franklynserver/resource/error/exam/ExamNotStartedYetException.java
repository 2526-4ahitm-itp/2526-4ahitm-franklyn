package at.ac.htlleonding.franklynserver.resource.error.exam;

import java.util.UUID;

import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("exam-not-started")
public class ExamNotStartedYetException extends GraphQLBusinessException {
    public ExamNotStartedYetException(UUID examId) {
        super(String.format("Exam '%s' was never started", examId));
    }

}

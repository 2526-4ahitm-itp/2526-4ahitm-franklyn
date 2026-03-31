package at.ac.htlleonding.franklynserver.resource.error.exam;

import java.util.UUID;

import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("exam-not-started")
public class ExamNotStartedYetException extends RuntimeException {
    public ExamNotStartedYetException(UUID examId) {
        super(String.format("Exam '%s' was never started", examId));
    }

}

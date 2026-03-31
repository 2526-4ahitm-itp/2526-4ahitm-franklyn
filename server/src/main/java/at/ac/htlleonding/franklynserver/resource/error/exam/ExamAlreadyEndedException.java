package at.ac.htlleonding.franklynserver.resource.error.exam;

import java.util.UUID;

import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("exam-already-ended")
public class ExamAlreadyEndedException extends RuntimeException {
    public ExamAlreadyEndedException(UUID examId) {
        super(String.format("Exam '%s' already ended", examId));
    }
}

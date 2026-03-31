package at.ac.htlleonding.franklynserver.resource.error.exam;

import java.util.UUID;

import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("exam-already-started")
public class ExamAlreadyStartedException extends RuntimeException {
    public ExamAlreadyStartedException(UUID examId) {
        super(String.format("Exam '%s' was already started", examId));
    }

}

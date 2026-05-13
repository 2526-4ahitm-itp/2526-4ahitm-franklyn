package at.ac.htlleonding.franklynserver.repository.exam.model;

import java.util.UUID;

import org.eclipse.microprofile.graphql.NonNull;

import io.smallrye.graphql.api.Nullable;

public record ExamSession(
        @NonNull UUID studentId,
        @NonNull UUID sentinelId,
        @NonNull UUID examId,
        @Nullable String videoFilePath) {
}

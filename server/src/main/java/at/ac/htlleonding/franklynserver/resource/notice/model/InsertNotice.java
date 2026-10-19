package at.ac.htlleonding.franklynserver.resource.notice.model;

import java.time.Instant;
import java.util.List;

import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import org.eclipse.microprofile.graphql.NonNull;

public record InsertNotice(@NonNull @NotNull NoticeType type,
        Instant startTime,
        Instant endTime,
        @NonNull @NotEmpty List<@NonNull @NotNull @Valid InsertNoticeContent> contents) {
}

package at.ac.htlleonding.franklynserver.repository.notice.model;

import jakarta.validation.constraints.Max;

import java.time.Instant;
import java.util.UUID;

public record Notice(
        UUID id,
        NoticeType type,

        Instant start_time,
        Instant end_time,

        @Max(1024)
        String content
) {
}

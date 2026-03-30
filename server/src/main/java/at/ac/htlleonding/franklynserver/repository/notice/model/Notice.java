package at.ac.htlleonding.franklynserver.repository.notice.model;

import jakarta.validation.constraints.Max;

import java.time.Instant;
import java.util.UUID;

public record Notice(UUID id, NoticeType type, Instant startTime, Instant endTime, @Max(1024) String content) {
}

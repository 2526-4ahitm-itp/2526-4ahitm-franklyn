package at.ac.htlleonding.franklynserver.resource.notice.model;

import java.time.Instant;

import at.ac.htlleonding.franklynserver.repository.notice.model.NoticeType;
import jakarta.validation.constraints.Max;

public record InsertNotice(NoticeType type, Instant startTime, Instant endTime, @Max(4096)
        String content) {

}

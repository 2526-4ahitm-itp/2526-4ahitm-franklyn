package at.ac.htlleonding.franklynserver.repository.notice.model;

import org.eclipse.microprofile.graphql.NonNull;

public record NoticeContent(@NonNull String language,
        @NonNull String content) {
}

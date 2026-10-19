package at.ac.htlleonding.franklynserver.resource.notice.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.eclipse.microprofile.graphql.NonNull;

public record InsertNoticeContent(@NonNull @NotBlank @Pattern(regexp = "[a-z]{2}") String language,
        @NonNull @NotBlank @Size(min = 3, max = 4096) String content) {
}

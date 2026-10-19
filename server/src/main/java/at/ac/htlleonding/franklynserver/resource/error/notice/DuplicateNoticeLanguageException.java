package at.ac.htlleonding.franklynserver.resource.error.notice;

import at.ac.htlleonding.franklynserver.resource.error.GraphQLBusinessException;
import io.smallrye.graphql.api.ErrorCode;

@ErrorCode("duplicate-notice-language")
public class DuplicateNoticeLanguageException extends GraphQLBusinessException {
    public DuplicateNoticeLanguageException(String language) {
        super(String.format("Notice contains more than one content for language '%s'.", language));
    }
}

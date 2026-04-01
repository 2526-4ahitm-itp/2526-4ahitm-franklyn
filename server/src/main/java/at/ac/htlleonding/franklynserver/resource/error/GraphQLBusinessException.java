package at.ac.htlleonding.franklynserver.resource.error;

import org.eclipse.microprofile.graphql.GraphQLException;
import org.jboss.logging.Logger;
import io.quarkus.logging.Log;

public class GraphQLBusinessException extends GraphQLException {

    private final Logger logger = Logger.getLogger(getClass());

    public GraphQLBusinessException(String msg) {
        super(msg, GraphQLException.ExceptionType.DataFetchingException);
        logger.warn(msg);
    }
}

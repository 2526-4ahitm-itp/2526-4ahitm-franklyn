package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.RecordingQueries;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Name;
import org.eclipse.microprofile.graphql.Query;

import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

@GraphQLApi
@ApplicationScoped
public class RecordingResource {
    @Inject
    RecordingQueries queries;

    @Query
    public List<RecordingQueries.FindAllRecordingsRow> recordings() {
        try {
            return queries.findAllRecordings();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
    @Query
    public Optional<RecordingQueries.FindRecordingByIdRow> recordingId(@Name("id") int id) {
        try {
            return queries.findRecordingById(id);
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
}

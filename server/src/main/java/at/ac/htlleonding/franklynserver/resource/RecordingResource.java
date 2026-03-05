package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.RecordingQueries;
import io.agroal.api.AgroalDataSource;
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
    AgroalDataSource dataSource;

    @Query
    public List<RecordingQueries.FindAllRecordingsRow> recordings() {
        try (var conn = dataSource.getConnection()) {
            return new RecordingQueries(conn).findAllRecordings();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Query
    public Optional<RecordingQueries.FindRecordingByIdRow> recordingId(@Name("id") int id) {
        try (var conn = dataSource.getConnection()) {
            return new RecordingQueries(conn).findRecordingById(id);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}

package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.model.Recording;
import at.ac.htlleonding.franklynserver.repository.RecordingQueries;
import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
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
    public List<Recording> recordings() {
        try {
            return queries.findAllRecordings().stream()
                    .map(row -> new Recording(
                            row.id(),
                            row.testId(),
                            row.startTime(),
                            row.endTime(),
                            row.studentName(),
                            row.videoFile(),
                            row.pcName()
                    )).toList();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
    @Query
    public Optional<Recording> recordingId(@Name("id") int id) {
        try {
            return queries.findRecordingById(id).stream()
                    .map(row -> new Recording(
                            row.id(),
                            row.testId(),
                            row.startTime(),
                            row.endTime(),
                            row.studentName(),
                            row.videoFile(),
                            row.pcName())).findFirst();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
}

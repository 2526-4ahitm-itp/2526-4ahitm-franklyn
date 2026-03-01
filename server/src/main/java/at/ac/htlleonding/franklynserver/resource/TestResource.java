package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.model.Teacher;
import at.ac.htlleonding.franklynserver.model.Test;
import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
import at.ac.htlleonding.franklynserver.repository.TestQueries;
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
public class TestResource {
    @Inject
    TestQueries queries;

    @Query
    public List<Test> tests() {
        try {
            return queries.findAllTests().stream()
                    .map(row -> new Test(
                            row.id(),
                            row.title(),
                            row.startTime(),
                            row.endTime(),
                            row.testAccountPrefix(),
                            row.teacherId()
                    )).toList();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
    @Query
    public Optional<Test> testId (@Name("id") long id) {
        try {
            return queries.findTestById(id).stream()
                    .map(row -> new Test(
                            row.id(),
                            row.title(),
                            row.startTime(),
                            row.endTime(),
                            row.testAccountPrefix(),
                            row.teacherId())).findFirst();
        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }
}

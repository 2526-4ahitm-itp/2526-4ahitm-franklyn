package at.ac.htlleonding.franklynserver.resource;

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
    public List<TestQueries.FindAllTestsRow> tests() {
        try {
            return queries.findAllTests();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
    @Query
    public Optional<TestQueries.FindTestByIdRow> testId (@Name("id") long id) {
        try {
            return queries.findTestById(id);
        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }
}

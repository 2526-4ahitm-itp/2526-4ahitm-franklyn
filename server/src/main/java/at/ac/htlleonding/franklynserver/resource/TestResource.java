package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.TestQueries;
import io.agroal.api.AgroalDataSource;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.GraphQLApi;
import org.eclipse.microprofile.graphql.Mutation;
import org.eclipse.microprofile.graphql.Name;
import org.eclipse.microprofile.graphql.Query;

import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

@GraphQLApi
@ApplicationScoped
public class TestResource {
    @Inject
    AgroalDataSource dataSource;

    @Query
    public List<TestQueries.FindAllTestsRow> tests() {
        try (var conn = dataSource.getConnection()) {
            return new TestQueries(conn).findAllTests();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Query
    public Optional<TestQueries.FindTestByIdRow> testId(@Name("id") long id) {
        try (var conn = dataSource.getConnection()) {
            return new TestQueries(conn).findTestById(id);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Mutation
    public Optional<TestQueries.InsertTestRow> createTest(TestQueries.InsertTestRow test) throws SQLException {
        try (var conn = dataSource.getConnection()) {
            return new TestQueries(conn).insertTest(test.id()
                    , test.teacherId()
                    , test.title()
                    , test.testAccountPrefix()
                    , test.endTime()
                    , test.startTime());
        }
    }

    @Mutation
    public Optional<TestQueries.UpdateTestRow> updateTest(long id, TestQueries.UpdateTestRow test) throws SQLException {
        try (var conn = dataSource.getConnection()) {
            return new TestQueries(conn).updateTest(
                    test.title()
                    , test.testAccountPrefix()
                    , test.endTime()
                    , test.startTime()
                    , id);
        }
    }

    @Mutation
    public Optional<TestQueries.DeleteTestRow> deleteTest(long id) throws SQLException {
        try (var conn = dataSource.getConnection()) {
            return new TestQueries(conn).deleteTest(id);
        }
    }
}

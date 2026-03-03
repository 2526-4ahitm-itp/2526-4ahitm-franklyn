package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.TestQueries;
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
    TestQueries queries;

    @Query
    public List<TestQueries.FindAllTestsRow> tests() {
        try {
            return queries.findAllTests();
        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }

    @Query
    public Optional<TestQueries.FindTestByIdRow> testId(@Name("id") long id) {
        try {
            return queries.findTestById(id);
        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }

    @Mutation
    public Optional<TestQueries.InsertTestRow> createTest(TestQueries.InsertTestRow test) throws SQLException {
        ;
        return queries.insertTest(test.id()
                , test.teacherId()
                , test.title()
                , test.testAccountPrefix()
                , test.endTime()
                , test.startTime());
    }
    @Mutation
    public Optional<TestQueries.UpdateTestRow> updateTest(long id, TestQueries.UpdateTestRow test) throws SQLException {
        return queries.updateTest(
                 test.title()
                , test.testAccountPrefix()
                , test.endTime()
                , test.startTime()
                , id);
    }
    @Mutation
    public Optional<TestQueries.DeleteTestRow> deleteTest(long id) throws SQLException {
        return queries.deleteTest(id);
    }

}

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
//    @Inject
//    TestQueries queries;
    @Inject
    AgroalDataSource dataSource;

    @Query
    public List<TestQueries.FindAllTestsRow> tests() {

        try (var conn = dataSource.getConnection()){
            TestQueries queries1 = new TestQueries(conn);
            return queries1.findAllTests();
        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }

    @Query
    public Optional<TestQueries.FindTestByIdRow> testId(@Name("id") long id) {
        try (var conn = dataSource.getConnection()){
            TestQueries queries1 = new TestQueries(conn);
            return queries1.findTestById(id);
        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }

    @Mutation
    public Optional<TestQueries.InsertTestRow> createTest(TestQueries.InsertTestRow test) {

        try (var conn = dataSource.getConnection()) {
            TestQueries queries1 = new TestQueries(conn);
            return queries1.insertTest(test.teacherId()
                    , test.title()
                    , test.testAccountPrefix()
                    , test.endTime()
                    , test.startTime());
        } catch (SQLException e) {
            throw new RuntimeException();
        }

    }
    @Mutation
    public Optional<TestQueries.UpdateTestRow> updateTest(long id, TestQueries.UpdateTestRow test) {
        try (var conn = dataSource.getConnection()) {
            TestQueries queries1 = new TestQueries(conn);
            return queries1.updateTest(
                    test.title()
                    , test.testAccountPrefix()
                    , test.endTime()
                    , test.startTime()
                    , id);
        } catch (SQLException e) {
            throw new RuntimeException();
        }

    }
    @Mutation
    public Optional<TestQueries.DeleteTestRow> deleteTest(long id) {

        try (var conn = dataSource.getConnection()) {
            TestQueries queries1 = new TestQueries(conn);
            return queries1.deleteTest(id);

        } catch (SQLException e) {
            throw new RuntimeException();
        }
    }

}

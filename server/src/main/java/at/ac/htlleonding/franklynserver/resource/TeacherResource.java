package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
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
public class TeacherResource {
    @Inject
    AgroalDataSource dataSource;

    @Query
    public List<TeacherQueries.FindAllTeachersRow> getTeachers() {
        try (var conn = dataSource.getConnection()) {
            return new TeacherQueries(conn).findAllTeachers();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @Query
    public Optional<TeacherQueries.FindTeacherByIdRow> teacherId(@Name("id") int id) {
        try (var conn = dataSource.getConnection()) {
            return new TeacherQueries(conn).findTeacherById(id);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}

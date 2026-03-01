package at.ac.htlleonding.franklynserver.resource;

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
public class TeacherResource {
    @Inject
    TeacherQueries queries;

    @Query
    public List<TeacherQueries.FindAllTeachersRow> getTeachers() {
        try {
            return queries.findAllTeachers();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
    @Query
    public Optional<TeacherQueries.FindTeacherByIdRow> teacherId(@Name("id") int id) {
        try {
            return queries.findTeacherById(id);
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
}

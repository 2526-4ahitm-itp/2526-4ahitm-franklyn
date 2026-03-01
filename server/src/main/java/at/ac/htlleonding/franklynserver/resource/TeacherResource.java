package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.ApplicationPath;
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
    public List<Teacher> getTeachers() {
        try {
            return queries.findAllTeachers()
                    .stream()
                    .map(row -> new Teacher(
                            row.id(),
                            row.name()
                    )).toList();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
    @Query
    public Optional<Teacher> teacherId(@Name("id") int id) {
        try {
            return queries.findTeacherById(id)
                    .stream()
                    .map(row -> new Teacher(
                            row.id(),
                            row.name()
                    )).findFirst();
        } catch(SQLException e) {
            throw new RuntimeException();
        }
    }
}

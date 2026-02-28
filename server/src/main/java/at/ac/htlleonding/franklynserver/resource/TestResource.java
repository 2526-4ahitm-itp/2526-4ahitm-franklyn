package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.model.Teacher;
import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.Query;

import java.util.List;

public class TestResource {

    @Inject
    TeacherQueries queries;

    @Query
    public List<Teacher> teachers() {

        return null;
    }
}

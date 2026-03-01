package at.ac.htlleonding.franklynserver.producer;

import at.ac.htlleonding.franklynserver.repository.RecordingQueries;
import at.ac.htlleonding.franklynserver.repository.TestQueries;
import jakarta.enterprise.context.RequestScoped;
import jakarta.enterprise.inject.Produces;

import java.sql.Connection;

import at.ac.htlleonding.franklynserver.repository.TeacherQueries;

@RequestScoped
public class QueryProducer {

    @Produces
    @RequestScoped
    public TeacherQueries produceTeacherQueries(Connection connection) {
        return new TeacherQueries(connection);
    }
    @Produces
    @RequestScoped
    public TestQueries produceTestQueries(Connection connection) {
        return new TestQueries(connection);
    }
    @Produces
    @RequestScoped
    public RecordingQueries produceRecordingQueries(Connection connection) {
        return new RecordingQueries(connection);
    }
}
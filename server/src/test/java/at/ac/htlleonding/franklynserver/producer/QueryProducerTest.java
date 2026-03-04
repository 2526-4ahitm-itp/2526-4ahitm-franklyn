package at.ac.htlleonding.franklynserver.producer;

import at.ac.htlleonding.franklynserver.repository.RecordingQueries;
import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
import at.ac.htlleonding.franklynserver.repository.TestQueries;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.sql.Connection;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class QueryProducerTest {

    private QueryProducer queryProducer;
    private Connection mockConnection;

    @BeforeEach
    void setUp() {
        queryProducer = new QueryProducer();
        mockConnection = mock(Connection.class);
    }

    @Test
    void produceTeacherQueries_returnsNewTeacherQueriesInstance() {
        TeacherQueries result = queryProducer.produceTeacherQueries(mockConnection);

        assertThat(result).isNotNull();
        assertThat(result).isInstanceOf(TeacherQueries.class);
    }

    @Test
    void produceTeacherQueries_returnsDifferentInstancesOnMultipleCalls() {
        TeacherQueries first = queryProducer.produceTeacherQueries(mockConnection);
        TeacherQueries second = queryProducer.produceTeacherQueries(mockConnection);

        assertThat(first).isNotSameAs(second);
    }

    @Test
    void produceTestQueries_returnsNewTestQueriesInstance() {
        TestQueries result = queryProducer.produceTestQueries(mockConnection);

        assertThat(result).isNotNull();
        assertThat(result).isInstanceOf(TestQueries.class);
    }

    @Test
    void produceTestQueries_returnsDifferentInstancesOnMultipleCalls() {
        TestQueries first = queryProducer.produceTestQueries(mockConnection);
        TestQueries second = queryProducer.produceTestQueries(mockConnection);

        assertThat(first).isNotSameAs(second);
    }

    @Test
    void produceRecordingQueries_returnsNewRecordingQueriesInstance() {
        RecordingQueries result = queryProducer.produceRecordingQueries(mockConnection);

        assertThat(result).isNotNull();
        assertThat(result).isInstanceOf(RecordingQueries.class);
    }

    @Test
    void produceRecordingQueries_returnsDifferentInstancesOnMultipleCalls() {
        RecordingQueries first = queryProducer.produceRecordingQueries(mockConnection);
        RecordingQueries second = queryProducer.produceRecordingQueries(mockConnection);

        assertThat(first).isNotSameAs(second);
    }

    @Test
    void produceTeacherQueries_withDifferentConnections_returnsDifferentInstances() {
        Connection anotherConnection = mock(Connection.class);

        TeacherQueries first = queryProducer.produceTeacherQueries(mockConnection);
        TeacherQueries second = queryProducer.produceTeacherQueries(anotherConnection);

        assertThat(first).isNotSameAs(second);
    }

    @Test
    void produceTestQueries_withDifferentConnections_returnsDifferentInstances() {
        Connection anotherConnection = mock(Connection.class);

        TestQueries first = queryProducer.produceTestQueries(mockConnection);
        TestQueries second = queryProducer.produceTestQueries(anotherConnection);

        assertThat(first).isNotSameAs(second);
    }

    @Test
    void produceRecordingQueries_withDifferentConnections_returnsDifferentInstances() {
        Connection anotherConnection = mock(Connection.class);

        RecordingQueries first = queryProducer.produceRecordingQueries(mockConnection);
        RecordingQueries second = queryProducer.produceRecordingQueries(anotherConnection);

        assertThat(first).isNotSameAs(second);
    }
}

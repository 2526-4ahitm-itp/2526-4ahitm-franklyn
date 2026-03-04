package at.ac.htlleonding.franklynserver.producer;

import io.agroal.api.AgroalDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.SQLException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ConnectionProducerTest {

    private ConnectionProducer connectionProducer;
    private AgroalDataSource mockDataSource;

    @BeforeEach
    void setUp() throws NoSuchFieldException, IllegalAccessException {
        connectionProducer = new ConnectionProducer();
        mockDataSource = mock(AgroalDataSource.class);

        var dataSourceField = ConnectionProducer.class.getDeclaredField("dataSource");
        dataSourceField.setAccessible(true);
        dataSourceField.set(connectionProducer, mockDataSource);
    }

    @Test
    void produceConnection_returnsConnectionFromDataSource() throws SQLException {
        Connection expectedConnection = mock(Connection.class);
        when(mockDataSource.getConnection()).thenReturn(expectedConnection);

        Connection result = connectionProducer.produceConnection();

        assertThat(result).isSameAs(expectedConnection);
        verify(mockDataSource).getConnection();
    }

    @Test
    void produceConnection_propagatesSQLException() throws SQLException {
        SQLException expectedException = new SQLException("Connection failed");
        when(mockDataSource.getConnection()).thenThrow(expectedException);

        assertThatThrownBy(() -> connectionProducer.produceConnection())
                .isInstanceOf(SQLException.class)
                .hasMessage("Connection failed");
    }

    @Test
    void produceConnection_callsDataSourceEachTime() throws SQLException {
        Connection connection1 = mock(Connection.class);
        Connection connection2 = mock(Connection.class);
        when(mockDataSource.getConnection())
                .thenReturn(connection1)
                .thenReturn(connection2);

        Connection firstResult = connectionProducer.produceConnection();
        Connection secondResult = connectionProducer.produceConnection();

        assertThat(firstResult).isSameAs(connection1);
        assertThat(secondResult).isSameAs(connection2);
    }
}

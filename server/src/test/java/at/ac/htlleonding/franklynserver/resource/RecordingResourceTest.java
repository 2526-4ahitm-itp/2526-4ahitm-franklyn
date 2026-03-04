package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.RecordingQueries;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class RecordingResourceTest {

    @Mock
    private RecordingQueries queries;

    @InjectMocks
    private RecordingResource recordingResource;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void recordings_returnsAllRecordings() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var recording1 = new RecordingQueries.FindAllRecordingsRow(endTime, 1L, startTime, 100L, "PC-01", "Alice", "video1.mp4");
        var recording2 = new RecordingQueries.FindAllRecordingsRow(endTime, 2L, startTime, 101L, "PC-02", "Bob", "video2.mp4");
        when(queries.findAllRecordings()).thenReturn(List.of(recording1, recording2));

        var result = recordingResource.recordings();

        assertThat(result).hasSize(2);
        assertThat(result).containsExactly(recording1, recording2);
        verify(queries).findAllRecordings();
    }

    @Test
    void recordings_returnsEmptyListWhenNoRecordings() throws SQLException {
        when(queries.findAllRecordings()).thenReturn(List.of());

        var result = recordingResource.recordings();

        assertThat(result).isEmpty();
        verify(queries).findAllRecordings();
    }

    @Test
    void recordings_throwsRuntimeExceptionOnSQLException() throws SQLException {
        when(queries.findAllRecordings()).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> recordingResource.recordings())
                .isInstanceOf(RuntimeException.class);
        verify(queries).findAllRecordings();
    }

    @Test
    void recordings_handlesRecordingsWithNullFields() throws SQLException {
        var recording = new RecordingQueries.FindAllRecordingsRow(null, 1L, null, null, null, null, null);
        when(queries.findAllRecordings()).thenReturn(List.of(recording));

        var result = recordingResource.recordings();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).endTime()).isNull();
        assertThat(result.get(0).startTime()).isNull();
        assertThat(result.get(0).testId()).isNull();
        assertThat(result.get(0).pcName()).isNull();
        assertThat(result.get(0).studentName()).isNull();
        assertThat(result.get(0).videoFile()).isNull();
    }

    @Test
    void recordingId_returnsRecordingWhenFound() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var recording = new RecordingQueries.FindRecordingByIdRow(endTime, 1L, startTime, 100L, "PC-01", "Alice", "video1.mp4");
        when(queries.findRecordingById(1L)).thenReturn(Optional.of(recording));

        var result = recordingResource.recordingId(1);

        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(recording);
        verify(queries).findRecordingById(1L);
    }

    @Test
    void recordingId_returnsEmptyWhenNotFound() throws SQLException {
        when(queries.findRecordingById(999L)).thenReturn(Optional.empty());

        var result = recordingResource.recordingId(999);

        assertThat(result).isEmpty();
        verify(queries).findRecordingById(999L);
    }

    @Test
    void recordingId_throwsRuntimeExceptionOnSQLException() throws SQLException {
        when(queries.findRecordingById(anyLong())).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> recordingResource.recordingId(1))
                .isInstanceOf(RuntimeException.class);
        verify(queries).findRecordingById(1L);
    }

    @Test
    void recordingId_returnsRecordingWithNullFields() throws SQLException {
        var recording = new RecordingQueries.FindRecordingByIdRow(null, 1L, null, null, null, null, null);
        when(queries.findRecordingById(1L)).thenReturn(Optional.of(recording));

        var result = recordingResource.recordingId(1);

        assertThat(result).isPresent();
        assertThat(result.get().endTime()).isNull();
        assertThat(result.get().startTime()).isNull();
        assertThat(result.get().testId()).isNull();
        assertThat(result.get().pcName()).isNull();
        assertThat(result.get().studentName()).isNull();
        assertThat(result.get().videoFile()).isNull();
    }
}

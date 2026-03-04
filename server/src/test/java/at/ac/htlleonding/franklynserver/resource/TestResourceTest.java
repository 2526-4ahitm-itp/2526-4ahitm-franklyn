package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.TestQueries;
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

class TestResourceTest {

    @Mock
    private TestQueries queries;

    @InjectMocks
    private TestResource testResource;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void tests_returnsAllTests() throws SQLException {
        var test1 = new TestQueries.FindAllTestsRow(1L, 100L, "Math Test", "MATH_", LocalDateTime.now(), LocalDateTime.now().minusHours(1));
        var test2 = new TestQueries.FindAllTestsRow(2L, 101L, "Science Test", "SCI_", LocalDateTime.now(), LocalDateTime.now().minusHours(2));
        when(queries.findAllTests()).thenReturn(List.of(test1, test2));

        var result = testResource.tests();

        assertThat(result).hasSize(2);
        assertThat(result).containsExactly(test1, test2);
        verify(queries).findAllTests();
    }

    @Test
    void tests_returnsEmptyListWhenNoTests() throws SQLException {
        when(queries.findAllTests()).thenReturn(List.of());

        var result = testResource.tests();

        assertThat(result).isEmpty();
        verify(queries).findAllTests();
    }

    @Test
    void tests_throwsRuntimeExceptionOnSQLException() throws SQLException {
        when(queries.findAllTests()).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> testResource.tests())
                .isInstanceOf(RuntimeException.class);
        verify(queries).findAllTests();
    }

    @Test
    void testId_returnsTestWhenFound() throws SQLException {
        var test = new TestQueries.FindTestByIdRow(1L, 100L, "Math Test", "MATH_", LocalDateTime.now(), LocalDateTime.now().minusHours(1));
        when(queries.findTestById(1L)).thenReturn(Optional.of(test));

        var result = testResource.testId(1L);

        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(test);
        verify(queries).findTestById(1L);
    }

    @Test
    void testId_returnsEmptyWhenNotFound() throws SQLException {
        when(queries.findTestById(999L)).thenReturn(Optional.empty());

        var result = testResource.testId(999L);

        assertThat(result).isEmpty();
        verify(queries).findTestById(999L);
    }

    @Test
    void testId_throwsRuntimeExceptionOnSQLException() throws SQLException {
        when(queries.findTestById(anyLong())).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> testResource.testId(1L))
                .isInstanceOf(RuntimeException.class);
        verify(queries).findTestById(1L);
    }

    @Test
    void createTest_insertsAndReturnsTest() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var inputTest = new TestQueries.InsertTestRow(1L, 100L, "New Test", "TEST_", endTime, startTime);
        var insertedTest = new TestQueries.InsertTestRow(1L, 100L, "New Test", "TEST_", endTime, startTime);
        when(queries.insertTest(1L, 100L, "New Test", "TEST_", endTime, startTime))
                .thenReturn(Optional.of(insertedTest));

        var result = testResource.createTest(inputTest);

        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(insertedTest);
        verify(queries).insertTest(1L, 100L, "New Test", "TEST_", endTime, startTime);
    }

    @Test
    void createTest_returnsEmptyWhenInsertFails() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var inputTest = new TestQueries.InsertTestRow(1L, 100L, "New Test", "TEST_", endTime, startTime);
        when(queries.insertTest(1L, 100L, "New Test", "TEST_", endTime, startTime))
                .thenReturn(Optional.empty());

        var result = testResource.createTest(inputTest);

        assertThat(result).isEmpty();
    }

    @Test
    void createTest_throwsSQLExceptionOnError() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var inputTest = new TestQueries.InsertTestRow(1L, 100L, "New Test", "TEST_", endTime, startTime);
        when(queries.insertTest(anyLong(), anyLong(), anyString(), anyString(), any(), any()))
                .thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> testResource.createTest(inputTest))
                .isInstanceOf(SQLException.class);
    }

    @Test
    void updateTest_updatesAndReturnsTest() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var updateData = new TestQueries.UpdateTestRow(1L, 100L, "Updated Test", "UPD_", endTime, startTime);
        var updatedTest = new TestQueries.UpdateTestRow(1L, 100L, "Updated Test", "UPD_", endTime, startTime);
        when(queries.updateTest("Updated Test", "UPD_", endTime, startTime, 1L))
                .thenReturn(Optional.of(updatedTest));

        var result = testResource.updateTest(1L, updateData);

        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(updatedTest);
        verify(queries).updateTest("Updated Test", "UPD_", endTime, startTime, 1L);
    }

    @Test
    void updateTest_returnsEmptyWhenTestNotFound() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var updateData = new TestQueries.UpdateTestRow(999L, 100L, "Updated Test", "UPD_", endTime, startTime);
        when(queries.updateTest("Updated Test", "UPD_", endTime, startTime, 999L))
                .thenReturn(Optional.empty());

        var result = testResource.updateTest(999L, updateData);

        assertThat(result).isEmpty();
    }

    @Test
    void updateTest_throwsSQLExceptionOnError() throws SQLException {
        var startTime = LocalDateTime.now().minusHours(1);
        var endTime = LocalDateTime.now();
        var updateData = new TestQueries.UpdateTestRow(1L, 100L, "Updated Test", "UPD_", endTime, startTime);
        when(queries.updateTest(anyString(), anyString(), any(), any(), anyLong()))
                .thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> testResource.updateTest(1L, updateData))
                .isInstanceOf(SQLException.class);
    }

    @Test
    void deleteTest_deletesAndReturnsDeletedTest() throws SQLException {
        var deletedTest = new TestQueries.DeleteTestRow(1L, 100L, "Deleted Test", "DEL_", LocalDateTime.now(), LocalDateTime.now().minusHours(1));
        when(queries.deleteTest(1L)).thenReturn(Optional.of(deletedTest));

        var result = testResource.deleteTest(1L);

        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(deletedTest);
        verify(queries).deleteTest(1L);
    }

    @Test
    void deleteTest_returnsEmptyWhenTestNotFound() throws SQLException {
        when(queries.deleteTest(999L)).thenReturn(Optional.empty());

        var result = testResource.deleteTest(999L);

        assertThat(result).isEmpty();
        verify(queries).deleteTest(999L);
    }

    @Test
    void deleteTest_throwsSQLExceptionOnError() throws SQLException {
        when(queries.deleteTest(anyLong())).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> testResource.deleteTest(1L))
                .isInstanceOf(SQLException.class);
    }
}

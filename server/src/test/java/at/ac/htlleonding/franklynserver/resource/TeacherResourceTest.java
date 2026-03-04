package at.ac.htlleonding.franklynserver.resource;

import at.ac.htlleonding.franklynserver.repository.TeacherQueries;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.sql.SQLException;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class TeacherResourceTest {

    @Mock
    private TeacherQueries queries;

    @InjectMocks
    private TeacherResource teacherResource;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getTeachers_returnsAllTeachers() throws SQLException {
        var teacher1 = new TeacherQueries.FindAllTeachersRow(1L, "John Doe");
        var teacher2 = new TeacherQueries.FindAllTeachersRow(2L, "Jane Smith");
        when(queries.findAllTeachers()).thenReturn(List.of(teacher1, teacher2));

        var result = teacherResource.getTeachers();

        assertThat(result).hasSize(2);
        assertThat(result).containsExactly(teacher1, teacher2);
        verify(queries).findAllTeachers();
    }

    @Test
    void getTeachers_returnsEmptyListWhenNoTeachers() throws SQLException {
        when(queries.findAllTeachers()).thenReturn(List.of());

        var result = teacherResource.getTeachers();

        assertThat(result).isEmpty();
        verify(queries).findAllTeachers();
    }

    @Test
    void getTeachers_throwsRuntimeExceptionOnSQLException() throws SQLException {
        when(queries.findAllTeachers()).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> teacherResource.getTeachers())
                .isInstanceOf(RuntimeException.class);
        verify(queries).findAllTeachers();
    }

    @Test
    void getTeachers_handlesTeachersWithNullNames() throws SQLException {
        var teacher1 = new TeacherQueries.FindAllTeachersRow(1L, null);
        var teacher2 = new TeacherQueries.FindAllTeachersRow(2L, "Jane Smith");
        when(queries.findAllTeachers()).thenReturn(List.of(teacher1, teacher2));

        var result = teacherResource.getTeachers();

        assertThat(result).hasSize(2);
        assertThat(result.get(0).name()).isNull();
        assertThat(result.get(1).name()).isEqualTo("Jane Smith");
    }

    @Test
    void teacherId_returnsTeacherWhenFound() throws SQLException {
        var teacher = new TeacherQueries.FindTeacherByIdRow(1L, "John Doe");
        when(queries.findTeacherById(1L)).thenReturn(Optional.of(teacher));

        var result = teacherResource.teacherId(1);

        assertThat(result).isPresent();
        assertThat(result.get()).isEqualTo(teacher);
        verify(queries).findTeacherById(1L);
    }

    @Test
    void teacherId_returnsEmptyWhenNotFound() throws SQLException {
        when(queries.findTeacherById(999L)).thenReturn(Optional.empty());

        var result = teacherResource.teacherId(999);

        assertThat(result).isEmpty();
        verify(queries).findTeacherById(999L);
    }

    @Test
    void teacherId_throwsRuntimeExceptionOnSQLException() throws SQLException {
        when(queries.findTeacherById(anyLong())).thenThrow(new SQLException("Database error"));

        assertThatThrownBy(() -> teacherResource.teacherId(1))
                .isInstanceOf(RuntimeException.class);
        verify(queries).findTeacherById(1L);
    }

    @Test
    void teacherId_returnsTeacherWithNullName() throws SQLException {
        var teacher = new TeacherQueries.FindTeacherByIdRow(1L, null);
        when(queries.findTeacherById(1L)).thenReturn(Optional.of(teacher));

        var result = teacherResource.teacherId(1);

        assertThat(result).isPresent();
        assertThat(result.get().name()).isNull();
    }
}

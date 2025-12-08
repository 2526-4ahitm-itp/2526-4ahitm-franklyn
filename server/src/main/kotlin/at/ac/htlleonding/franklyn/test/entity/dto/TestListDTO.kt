package at.ac.htlleonding.franklyn.test.entity.dto

import java.time.LocalDateTime

data class TestListDTO(
    val id: Long?,
    val title: String,
    val start: LocalDateTime?,
    val end: LocalDateTime?,
    val teacherId: Long?
)


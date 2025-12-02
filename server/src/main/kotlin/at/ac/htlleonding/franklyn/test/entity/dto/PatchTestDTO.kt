package at.ac.htlleonding.franklyn.test.entity.dto

import java.time.LocalDateTime

data class PatchTestDTO(
    var id: Long,
    var title: String?,
    var startTime: LocalDateTime?,
    var endTime: LocalDateTime?,
    var testAccountPrefix: String?,
)

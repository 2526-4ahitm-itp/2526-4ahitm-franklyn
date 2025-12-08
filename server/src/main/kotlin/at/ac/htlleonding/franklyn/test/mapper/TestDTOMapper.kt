package at.ac.htlleonding.franklyn.test.mapper

import at.ac.htlleonding.franklyn.test.entity.Test
import at.ac.htlleonding.franklyn.test.entity.dto.CreateTestDTO
import at.ac.htlleonding.franklyn.test.entity.dto.TestListDTO

object TestDTOMapper {
    fun toDTO(test: Test): CreateTestDTO = CreateTestDTO(test.title, test.testAccountPrefix)

    fun fromDTO(testDTO: CreateTestDTO) = Test(testDTO.title, testDTO.testAccountPrefix)

    fun toListDTO(test: Test): TestListDTO =
        TestListDTO(
            id = test.id,
            title = test.title,
            testAccountPrefix = test.testAccountPrefix,
            start = test.startTime,
            end = test.endTime,
            teacherId = test.teacher.id
        )
}

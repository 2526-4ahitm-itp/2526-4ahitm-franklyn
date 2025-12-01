package at.ac.htlleonding.franklyn.test.mapper

import at.ac.htlleonding.franklyn.test.entity.Test
import at.ac.htlleonding.franklyn.test.entity.dto.CreateTestDTO

object TestDTOMapper {
    fun toDTO(test: Test): CreateTestDTO = CreateTestDTO(test.title, test.testAccountPrefix)

    fun fromDTO(testDTO: CreateTestDTO) = Test(testDTO.title, testDTO.testAccountPrefix)
}

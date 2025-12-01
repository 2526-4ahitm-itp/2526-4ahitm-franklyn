package at.ac.htlleonding.franklyn.testrecording.entity

import at.ac.htlleonding.franklyn.test.entity.Test
import io.quarkus.hibernate.orm.panache.kotlin.PanacheEntityBase
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "fr_test_recording")
class TestRecording : PanacheEntityBase {

    @get:Id
    @get:GeneratedValue(
        strategy = GenerationType.SEQUENCE,
        generator = "test_recording_seq"
    )
    @get:SequenceGenerator(
        name = "test_recording_seq",
        sequenceName = "fr_test_recording_seq",
        allocationSize = 50,
        initialValue = 1
    )
    @get:Column(
        name = "id",
        nullable = false,
        updatable = false
    )
    var id: Long? = null

    @Column(nullable = false)
    lateinit var studentName: String

    lateinit var startTime: LocalDateTime
    lateinit var endTime: LocalDateTime

    lateinit var videoFile: String

    lateinit var pcName: String

    @get:ManyToOne
    @get:JoinColumn(name = "test_id")
    lateinit var test: Test
}

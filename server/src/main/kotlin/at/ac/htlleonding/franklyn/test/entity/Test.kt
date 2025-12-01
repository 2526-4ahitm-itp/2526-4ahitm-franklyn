package at.ac.htlleonding.franklyn.test.entity

import Teacher
import at.ac.htlleonding.franklyn.testrecording.entity.TestRecording
import io.quarkus.hibernate.orm.panache.kotlin.PanacheEntityBase
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "fr_test")
class Test : PanacheEntityBase {

    @get:Id
    @get:GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "test_seq")
    @get:SequenceGenerator(
        name = "test_seq",
        sequenceName = "fr_test_seq"
    )
    @get:Column(name = "id", nullable = false, updatable = false)
    var id: Long? = null

    @Column(nullable = false)
    lateinit var title: String

    lateinit var startTime: LocalDateTime
    lateinit var endTime: LocalDateTime

    lateinit var testAccountPrefix: String

    @get:ManyToOne
    @get:JoinColumn(name = "teacherId")
    lateinit var teacher: Teacher

    @get:OneToMany(mappedBy = "test")
    lateinit var testRecordings: MutableSet<TestRecording>
}

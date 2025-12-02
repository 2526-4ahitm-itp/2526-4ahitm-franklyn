package at.ac.htlleonding.franklyn.test.entity

import at.ac.htlleonding.franklyn.teacher.entity.Teacher
import at.ac.htlleonding.franklyn.testrecording.entity.TestRecording
import io.quarkus.hibernate.orm.panache.kotlin.PanacheCompanion
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

    var startTime: LocalDateTime? = null
    var endTime: LocalDateTime? = null

    lateinit var testAccountPrefix: String

    @get:ManyToOne
    @get:JoinColumn(name = "teacherId")
    lateinit var teacher: Teacher

    @get:OneToMany(mappedBy = "test")
    var testRecordings: MutableSet<TestRecording> = mutableSetOf()
    
    constructor()
    
    constructor(title: String, testAccountPrefix: String) {
        this.title = title
        this.testAccountPrefix = testAccountPrefix
    }

    companion object : PanacheCompanion<Test> {
        fun findByTeacher(teacher: Teacher) = find("teacher", teacher).list()
    }
}

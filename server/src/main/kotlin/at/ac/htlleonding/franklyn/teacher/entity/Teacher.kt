import at.ac.htlleonding.franklyn.test.entity.Test
import io.quarkus.hibernate.orm.panache.kotlin.PanacheEntityBase
import io.quarkus.security.identity.SecurityIdentity
import jakarta.persistence.*

@Entity
@Table(name = "fr_teacher")
class Teacher : PanacheEntityBase {

    @get:Id
    @get:GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "teacher_seq")
    @get:SequenceGenerator(
        name = "teacher_seq",
        sequenceName = "fr_teacher_seq",
        allocationSize = 50,
        initialValue = 1
    )
    @get:Column(name = "id", nullable = false, updatable = false)
    var id: Long? = null

    lateinit var name: String

    @get:OneToMany(mappedBy = "teacher")
    lateinit var tests: MutableSet<Test>

    constructor() {}

    constructor(identity: SecurityIdentity) {
        this.name = identity.getPrincipal().getName()
    }
}

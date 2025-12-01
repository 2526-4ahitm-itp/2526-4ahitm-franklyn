import io.quarkus.hibernate.orm.panache.kotlin.PanacheCompanion
import io.quarkus.hibernate.orm.panache.kotlin.PanacheEntityBase
import io.quarkus.runtime.LaunchMode
import io.quarkus.security.identity.SecurityIdentity
import jakarta.persistence.*

@Entity
@Table(name = "fr_teacher")
class Teacher : PanacheEntityBase {

    @get:Id
    @get:GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "teacher_seq")
    @get:SequenceGenerator(
        name = "teacher_seq",
        sequenceName = "fr_teacher_seq"
    )
    @get:Column(name = "id", nullable = false, updatable = false)
    var id: Long? = null

    lateinit var name: String


    constructor()

    constructor(identity: SecurityIdentity) {
        this.name = identity.principal.name
    }

    companion object : PanacheCompanion<Teacher> {

        fun findOrCreateTeacherInAuthContext(identity: SecurityIdentity): Teacher {
            val name: String =
                if (LaunchMode.current() == LaunchMode.DEVELOPMENT) {
                    "stuetz"
                } else {
                    identity.principal.name
                }

            return find("name", name).firstResult()
                ?: Teacher(identity).also {
                    it.name = name
                    it.persist()
                }
        }
        
    }
}

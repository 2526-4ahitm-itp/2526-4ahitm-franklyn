import io.quarkus.hibernate.orm.panache.kotlin.PanacheEntityBase
import io.quarkus.security.identity.SecurityIdentity
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id

@Entity
class Teacher : PanacheEntityBase {

    @get:Id
    @get:GeneratedValue(strategy = GenerationType.SEQUENCE)
    var id: Long? = null

    lateinit var name: String

    constructor() {}

    constructor(identity: SecurityIdentity) {
        this.name = identity.getPrincipal().getName()
    }
}

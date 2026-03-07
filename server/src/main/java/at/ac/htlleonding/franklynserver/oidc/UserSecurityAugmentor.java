package at.ac.htlleonding.franklynserver.oidc;

import io.quarkus.security.identity.AuthenticationRequestContext;
import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.identity.SecurityIdentityAugmentor;
import io.quarkus.security.runtime.QuarkusSecurityIdentity;
import io.smallrye.mutiny.Uni;
import jakarta.enterprise.context.ApplicationScoped;

import org.eclipse.microprofile.jwt.JsonWebToken;

@ApplicationScoped
public class UserSecurityAugmentor implements SecurityIdentityAugmentor {

    @Override
    public Uni<SecurityIdentity> augment(SecurityIdentity identity,
            AuthenticationRequestContext context) {
        if (identity.isAnonymous()) {
            return Uni.createFrom().item(identity);
        }

        if (!(identity.getPrincipal() instanceof JsonWebToken jwt)) {
            return Uni.createFrom().item(identity);
        }

        String ldapEntryDn = jwt.getClaim("ldap_entry_dn");

        return UserRole.fromLdapEntryDn(ldapEntryDn)
                .map(role -> QuarkusSecurityIdentity.builder(identity)
                        .addRole(role.roleName())
                        .build())
                .map(augmented -> Uni.createFrom().<SecurityIdentity>item(augmented))
                .orElse(Uni.createFrom().item(identity));
    }
}

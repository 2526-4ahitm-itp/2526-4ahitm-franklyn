package at.ac.htlleonding.franklynserver.oidc;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import io.quarkus.logging.Log;
import io.quarkus.security.identity.AuthenticationRequestContext;
import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.identity.SecurityIdentityAugmentor;
import io.quarkus.security.runtime.QuarkusSecurityIdentity;
import io.smallrye.mutiny.Uni;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import org.eclipse.microprofile.jwt.JsonWebToken;

@ApplicationScoped
public class UserSecurityAugmentor implements SecurityIdentityAugmentor {

    @Inject
    OidcUserService oidcUserService;

    @Override
    public Uni<SecurityIdentity> augment(SecurityIdentity identity,
            AuthenticationRequestContext context) {

        if (identity.isAnonymous()) {
            return Uni.createFrom().item(identity);
        }

        if (!(identity.getPrincipal() instanceof JsonWebToken jwt)) {
            Log.debugf("Unauthorized request: principal is not a JWT (%s)",
                    identity.getPrincipal().getClass().getName());
            return Uni.createFrom().item(identity);
        }

        String preferredUsername = jwt.getClaim("preferred_username");
        String ldapEntryDn = jwt.getClaim("distinguished_name");

        HashSet<String> roles = new HashSet<>();

        Log.debugf("Augmenting identity for user '%s', distinguished_name='%s', allclaims=%s",
                preferredUsername, ldapEntryDn, jwt.getClaimNames());

        Optional<UserRole> role = UserRole.fromDistinguishedName(ldapEntryDn);

        if (role.isEmpty()) {
            Log.warnf("User '%s' has no valid distinguished_name, no roles assigned",
                    preferredUsername);
            return Uni.createFrom().item(identity);
        }

        Log.debugf("User '%s' is of type '%s' with class '%s'",
                preferredUsername,
                role.get().name(),
                role.get().userClass());

        Log.debugf("User '%s' assigned roles '%s'", preferredUsername, roles);

        roles.add(role.get().roleName());

        var secIdentityBuilder = QuarkusSecurityIdentity.builder(identity);

        roles.forEach(secIdentityBuilder::addRole);

        return Uni.createFrom().item(secIdentityBuilder.build());
    }
}

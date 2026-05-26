## Why

No spec documents the auth-identity capability — how roles are determined, how each actor authenticates, and how Keycloak claims are mapped to application identity. Gaps exist in the Admin role (§2.1) and class extraction from `distinguishedName` (§4.1) that are invisible without a written spec.

## What Changes

- New spec `auth-identity` covering: Keycloak-based login for all three roles (§2, §5), LDAP `distinguishedName`→role/class mapping (§4.1), auto-provisioning of Teacher/Student DB records on first login, and sentinel OIDC PKCE flow (§5.1)
- Gaps documented as `[GAP]` tasks: Admin role not implemented in `UserRole.java`; class extraction from `distinguishedName` not implemented

## Capabilities

### New Capabilities

- `auth-identity`: Authentication flows, role derivation from Keycloak claims, user auto-provisioning, and identity resolution across all three actors (Schüler, Lehrer, Admin)

### Modified Capabilities

_None._

## Impact

- `server/src/.../oidc/UserRole.java` — Admin role gap
- `server/src/.../oidc/UserSecurityAugmentor.java` — role augmentation
- `server/src/.../oidc/OidcUserService.java` — user resolution and provisioning
- `sentinel/src/oidc.rs` — student PKCE auth flow
- `proctor/src/stores/KeycloakStore.ts` — teacher session management
- `proctor/src/stores/UserStore.ts` — teacher identity query

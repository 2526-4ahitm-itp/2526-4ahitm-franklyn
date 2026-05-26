## Context

Auth-identity spans all three actors (Schüler, Lehrer, Admin) and three subsystems (sentinel Rust daemon, proctor Vue.js frontend, server Java/Quarkus). Keycloak is the single identity provider for all actors. Role assignment is derived from LDAP claims in the JWT, not from Keycloak's own role system.

Current state: Teacher and Student flows are implemented. Admin role is absent from the codebase. Class extraction from `distinguishedName` is not implemented despite being required by §4.1.

## Goals / Non-Goals

**Goals:**
- Document the full auth-identity design including all three actors (§2, §5)
- Surface the Admin role gap and class extraction gap as tasks

**Non-Goals:**
- Implementing the gaps (tracked as `[GAP]` tasks in tasks.md)
- Token refresh lifecycle details (not spec-level)
- Keycloak realm configuration

## Decisions

**Role derived from LDAP `distinguishedName`, not Keycloak roles**: The JWT claim `distinguished_name` carries the LDAP DN (`OU=Teachers,...` / `OU=Students,...`). This avoids Keycloak role configuration drift and keeps role logic inside the application. Implication: Admin must also be expressed via `distinguishedName` (e.g., `OU=Admins`).

**Auto-provisioning on first login**: `OidcUserService` creates a Teacher or Student DB row on first successful authentication. This avoids any pre-seeding step and is idempotent (lookup before create). Admin users are not provisioned (no DB row expected for Admins).

**Sentinel uses PKCE OIDC (browser-based)**: Sentinel opens the system browser, starts a local callback server on a random port, and exchanges the code for tokens. This matches the student flow: Keycloak login → sentinel receives tokens → student enters PIN. The 5-minute OIDC timeout is hard-coded.

**Proctor uses keycloak-js with sessionStorage persistence**: Tokens are serialized into `sessionStorage.stored_session` and restored on page reload to avoid forcing re-login on refresh. Tokens older than 30s are refreshed proactively.

## Risks / Trade-offs

- [Admin role gap] No `OU=Admins` mapping exists → Admin users get no roles, cannot access admin endpoints. Mitigation: implement in `UserRole.java` as `[GAP]` task.
- [Class extraction gap] §4.1 requires class from `OU=<Klasse>` in DN (e.g., `OU=4AHITM`). Not extracted anywhere. Mitigation: implement extraction in `UserRole` or `OidcUserService` as `[GAP]` task.
- [sessionStorage token exposure] Tokens in sessionStorage are readable by XSS. Accepted risk for v1 (on-prem, school network context).

## 1. Spec: auth-identity

- [x] 1.1 [SPEC] Review spec `specs/auth-identity/spec.md` — confirm all scenarios match current implementation

## 2. Admin Role Gap

- [x] 2.1 [GAP] Add `ADMIN("admin", null)` variant to `UserRole.java` with `fromDistinguishedName` mapping for `OU=Admins`
- [x] 2.2 [GAP] Update `UserSecurityAugmentor.java` to assign role `admin` when UserRole is ADMIN
- [x] 2.3 [GAP] Verify Admin users are NOT auto-provisioned in `OidcUserService` (no DB entity expected)

## 3. Class Extraction Gap

- [x] 3.1 [GAP] Add `extractClass(String ldapEntryDn)` to `UserRole` or `OidcUserService` — parse `OU=<Klasse>` from DN, e.g. `OU=4AHITM`
- [x] 3.2 [GAP] Expose extracted class on the resolved `Student` entity so exam assignment can use it

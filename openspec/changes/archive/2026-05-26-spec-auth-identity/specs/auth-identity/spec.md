## ADDED Requirements

### Requirement: Role derivation from Keycloak distinguishedName
`status: partial`

The system SHALL derive the user's role (Schüler, Lehrer, Admin) from the `distinguished_name` JWT claim by inspecting the LDAP organizational unit. `OU=Students` → Schüler. `OU=Teachers` → Lehrer. `OU=Admins` → Admin. Users without a recognized OU SHALL receive no role.

#### Scenario: Student role assigned
- **WHEN** a JWT contains `distinguished_name` with `OU=Students`
- **THEN** the security identity is assigned role `student`

#### Scenario: Teacher role assigned
- **WHEN** a JWT contains `distinguished_name` with `OU=Teachers`
- **THEN** the security identity is assigned role `teacher`

#### Scenario: Admin role assigned
- **WHEN** a JWT contains `distinguished_name` with `OU=Admins`
- **THEN** the security identity is assigned role `admin`

#### Scenario: Unknown OU receives no role
- **WHEN** a JWT contains a `distinguished_name` with no recognized OU
- **THEN** the security identity is assigned no roles

### Requirement: Class extraction from distinguishedName
`status: not-implemented`

The system SHALL extract the student's class from the `distinguished_name` JWT claim by parsing the `OU=<Klasse>` component (e.g., `OU=4AHITM`). The extracted class SHALL be made available during exam assignment.

#### Scenario: Class extracted
- **WHEN** `distinguished_name` contains `OU=4AHITM`
- **THEN** the resolved class is `4AHITM`

#### Scenario: Missing class OU
- **WHEN** `distinguished_name` contains no class OU
- **THEN** class is `null` and the student is still authenticated

### Requirement: Student authentication via PKCE OIDC (sentinel)
`status: implemented`

The sentinel daemon SHALL authenticate the student using the PKCE Authorization Code flow against Keycloak. The daemon SHALL open the system browser, bind a local redirect server on a random free port, and exchange the authorization code for access, ID, and refresh tokens. Authentication SHALL time out after 300 seconds if no callback is received.

#### Scenario: Successful authentication
- **WHEN** the student completes login in the browser within 300 seconds
- **THEN** sentinel receives valid access_token, id_token, and optional refresh_token

#### Scenario: Authentication timeout
- **WHEN** no callback is received within 300 seconds
- **THEN** sentinel returns an `OidcError::Timeout` error

#### Scenario: State mismatch
- **WHEN** the callback state does not match the CSRF token
- **THEN** sentinel returns `OidcError::CallbackInvalid("state mismatch")`

### Requirement: Teacher/Admin authentication via keycloak-js (proctor)
`status: implemented`

The proctor frontend SHALL authenticate teachers and admins via Keycloak using `keycloak-js` with `login-required` mode. Sessions SHALL be persisted in `sessionStorage` and tokens proactively refreshed if older than 30 seconds on page load.

#### Scenario: First login
- **WHEN** no stored session exists
- **THEN** Keycloak login page is shown and tokens are stored in sessionStorage after success

#### Scenario: Session restored on page reload
- **WHEN** a valid stored session exists in sessionStorage
- **THEN** tokens are restored and refreshed without redirecting to Keycloak

#### Scenario: Stored session expired
- **WHEN** stored session exists but token refresh fails
- **THEN** sessionStorage is cleared and Keycloak login is triggered

### Requirement: User auto-provisioning on first login
`status: implemented`

The server SHALL automatically create a Teacher or Student DB record on the first successful authentication if no record exists for the user's Keycloak subject (UUID). Provisioning SHALL be idempotent: if the record already exists, the existing record is returned. Provisioned fields: `id` (Keycloak subject UUID), `preferredUsername`, `email`, `givenName`, `familyName`.

#### Scenario: New user provisioned
- **WHEN** a user authenticates whose UUID is not in the database
- **THEN** a new Teacher or Student record is created with Keycloak claim values

#### Scenario: Returning user resolved
- **WHEN** a user authenticates whose UUID already exists in the database
- **THEN** the existing record is returned without creating a duplicate

#### Scenario: Admin not provisioned
- **WHEN** a user with Admin role authenticates
- **THEN** no DB record is created (Admins have no DB entity)

### Requirement: Role-based access control
`status: partial`

The system SHALL enforce that Lehrer can only access their own exam data (§13.2). Admin SHALL have full access to all data. Schüler SHALL have no access to the proctor UI.

#### Scenario: Lehrer accesses own exam
- **WHEN** a Lehrer requests data for an exam they created
- **THEN** the request succeeds

#### Scenario: Lehrer denied other exam
- **WHEN** a Lehrer requests data for an exam they did not create
- **THEN** the request is rejected with an authorization error

#### Scenario: Admin accesses any exam
- **WHEN** an Admin requests data for any exam
- **THEN** the request succeeds

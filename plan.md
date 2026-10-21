# User Model Refactor — Plan

## Goal

Replace `fr_teacher`/`fr_student` subtype tables with a single `fr_user` + `fr_settings` model.
Every DB-touching operation uses an **upsert** to provision/update the user.
Settings become a GraphQL sub-selectable type on User.

---

## Phase 1 — Delete dead code

| Action | File |
|--------|------|
| Delete | `TeacherDetails.java` |
| Delete | `StudentDetails.java` |
| Delete | `RoleDetails.java` |

---

## Phase 2 — Simplify `UserRole`

Strip `roleClass` field. Keep `fromDistinguishedName`.

```java
public enum UserRole {
    TEACHER, STUDENT;
    // fromDistinguishedName stays as-is
}
```

---

## Phase 3 — Slim down `User` record

Remove `language`, `theme`, `details`. Result:

```java
public record User(
    UUID id,
    String preferredUsername,
    String email,
    @Nullable String givenName,
    @Nullable String familyName,
    UserRole role
) {}
```

---

## Phase 4 — New `UserSettings` record

```java
public record UserSettings(
    UUID userId,
    UserTheme theme,
    String language
) {}
```

Lives in `repository/user/model/`.

---

## Phase 5 — Rewrite `UserDao`

### 5a — Upsert user (replaces `insertUser` + `insertDetailedUser`)

```sql
INSERT INTO fr_user (id, preferred_username, email, given_name, family_name, role)
VALUES (:id, :preferredUsername, :email, :givenName, :familyName, :role::fr_user_type)
ON CONFLICT (id) DO UPDATE SET
    preferred_username = EXCLUDED.preferred_username,
    email = EXCLUDED.email,
    given_name = EXCLUDED.given_name,
    family_name = EXCLUDED.family_name
RETURNING id, preferred_username, email, given_name, family_name, role::text
```

Single call, always safe. Used everywhere a user is needed in DB.

### 5b — Settings queries

```sql
-- find
SELECT user_id, theme::text, language FROM fr_settings WHERE user_id = :userId

-- insert default on user provisioning (ignore if already exists)
INSERT INTO fr_settings (user_id, theme, language)
VALUES (:userId, :theme::fr_settings_theme, :language)
ON CONFLICT (user_id) DO NOTHING

-- update
UPDATE fr_settings SET
    theme = :theme::fr_settings_theme,
    language = :language
WHERE user_id = :userId
RETURNING user_id, theme::text, language
```

### 5c — Remove entirely

- `findTypedRoleDetails`
- `insertTypedRoleDetails`
- `insertDetailedUser`
- `updateUserSettingsInternal` / `updateUserSettings`
- All `TeacherDetails`/`StudentDetails` mapper registrations

### 5d — Update `findById` / `findByIdAndType`

Remove `theme::text, language` from SELECT. Just user columns + `role::text`.

---

## Phase 6 — Simplify `OidcUserService`

### `resolveJwtUser`
Build `User` without `language`/`theme`/`details`:
```java
return new User(id, jwt.getClaim("preferred_username"),
    jwt.getClaim("email"), jwt.getClaim("given_name"),
    jwt.getClaim("family_name"), role.get());
```

### `createUser` / `resolveUser`
Coordinated at the service level (no internal DAO transactions). Service uses `@Transactional` if needed on the public boundary:
```java
@Transactional
public User resolveUser() {
    User user = resolveJwtUser();
    User upserted = userDao.upsertUser(user);
    userDao.insertSettings(new UserSettings(upserted.id(), UserTheme.SYSTEM, "de"));
    return upserted;
}
```

---

## Phase 7 — Refactor `UserResource`

### `updateSettings` mutation
```java
@Mutation
public UserSettings updateSettings(@Valid UpdateUserSettings input) {
    User u = userService.resolveUser(UserRole.TEACHER);
    return userDao.updateSettings(u.id(), input.theme().getName(), input.language());
}
```

Returns `UserSettings` instead of `User`.

### `roleDetails` resolver — **delete entirely**

### `exams` resolver — re-source on `User`
```java
public List<Exam> exams(@Source User user) {
    requireTeacher(user);
    return examDao.findByTeacher(user.id());
}
```

### `settings` resolver — **new** (enables `user { settings { theme language } }`)
```java
public UserSettings settings(@Source User user) {
    return userDao.findSettings(user.id())
        .orElse(new UserSettings(user.id(), UserTheme.SYSTEM, "de"));
}
```

### `userById` query — **new**
```java
@Query
public Optional<User> userById(@NonNull UUID id) {
    return userDao.findById(id);
}
```

---

## Phase 8 — Fix `ExamResource`

### `teacher(@Source Exam)` resolver (L149-150)
```java
public User teacher(@Source Exam exam) {
    return userDao.findById(exam.teacherId()).get();
}
```
Drop `findByIdAndType` — just `findById`. Role is informational, not a lookup filter.

### `createExam` (L81)
Already calls `resolveUser(TEACHER)` which will upsert. No change needed.

---

## Phase 9 — Helper methods

Add to `UserResource` or a shared util:

```java
private void requireTeacher(User u) throws GraphQLBusinessException {
    if (u.role() != UserRole.TEACHER) {
        throw new UserTypeMismatchException(UserRole.TEACHER, u.role(), u.id());
    }
}
```

Same pattern for `requireStudent` if needed.

---

## Phase 10 — Tests

| File | Changes |
|------|---------|
| `UserDaoTest.java` | Remove `fr_teacher`/`fr_student` cleanup, remove `TeacherDetails`/`StudentDetails` usage, test upsert + settings queries |
| `VideoRetentionServiceTest.java` | Update `User` construction (no theme/language/details), remove `fr_teacher`/`fr_student` cleanup |

---

## Phase 11 — Proctor frontend

| File | Change |
|------|--------|
| `types/User.ts` | Remove `theme`, `language`. Add `Settings` type. |
| `services/user.ts` | `USER_QUERY`: replace inline `theme language` → `settings { theme language }`. `UPDATE_SETTINGS_MUTATION`: return `UserSettings` type. |
| `services/theme.ts` | Read `user.settings.theme` instead of `user.theme` |
| `views/SettingsView.vue` | Read/write via `user.settings.*` |
| `App.vue` | Read `user.settings.language` |

---

## Phase 12 — Docs (non-blocking)

| File | Change |
|------|--------|
| `hugo/.../schema.puml` | Remove `fr_teacher`/`fr_student`, add `fr_settings` |
| `openspec/.../auth-identity/spec.md` | Update "creates Teacher/Student record" text |

---

## Execution order

Phases 1-9 (server) → Phase 10 (tests) → Phase 11 (proctor) → Phase 12 (docs)

Within server: entity layer bottom-up (1→2→3→4→5→6→7→8→9).

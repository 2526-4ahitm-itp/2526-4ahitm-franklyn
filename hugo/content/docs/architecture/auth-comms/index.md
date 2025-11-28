---
title: Authentication Comms
date: 2025-11-28
---

```plantuml
@startuml
skinparam responseMessageBelowArrow true
autonumber "<b>[00]</b>"

participant "Frontend App" as FE
participant "Backend Server" as BE
participant "Keycloak (IdP)" as KC

title Authentication & Authorization Flow

== 1. Initial Unauthenticated Request ==
FE -> BE: GET /api/resource\n(No Authorization Header)
activate BE
BE --> FE: HTTP 401 Unauthorized
deactivate BE

== 2. Authentication (Login) ==
note right of FE: Handled by keycloak-js
FE -> KC: Redirect to Login Page\n(OIDC Authorization Code Flow)
activate KC
KC --> FE: HTTP 200 OK\nBody: { "access_token": "eyJh..." }
deactivate KC

== 3. Authenticated Request ==
FE -> BE: GET /api/resource\nAuthorization: Bearer <access_token>
activate BE

== 4. Validation & Authorization ==
note right of BE
    handled by quarkus
end note


BE -> KC: POST /introspect\nBody: token=<access_token>...
activate KC
KC --> BE: HTTP 200 OK\nBody: { "active": true, "roles": [...] }
deactivate KC

alt Token Valid AND User has Permission
    BE --> FE: HTTP 200 OK\nBody: { "data": "Protected Resource" }
else Token Invalid OR Resource Disallowed
    BE --> FE: HTTP 403 Forbidden\nBody: { "error": "Access Denied" }
end

deactivate BE
@enduml
```

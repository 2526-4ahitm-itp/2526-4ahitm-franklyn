# Graph Report - .  (2026-05-28)

## Corpus Check
- 68 files · ~62,497 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 127 nodes · 141 edges · 37 communities (31 shown, 6 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 12 edges (avg confidence: 0.86)
- Token cost: 173,638 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Exam List UI & Status|Exam List UI & Status]]
- [[_COMMUNITY_App Bootstrap & Auth Wiring|App Bootstrap & Auth Wiring]]
- [[_COMMUNITY_Live Proctoring & WebSocket Protocol|Live Proctoring & WebSocket Protocol]]
- [[_COMMUNITY_Project Docs & Decisions|Project Docs & Decisions]]
- [[_COMMUNITY_Migration Phases & Rules|Migration Phases & Rules]]
- [[_COMMUNITY_GraphQL Services & Data Layer|GraphQL Services & Data Layer]]
- [[_COMMUNITY_Auth, Theme & Cleanup Phases|Auth, Theme & Cleanup Phases]]
- [[_COMMUNITY_Domain Types (UserThemeRole)|Domain Types (User/Theme/Role)]]
- [[_COMMUNITY_Architecture Rationale|Architecture Rationale]]
- [[_COMMUNITY_Vite Env Types|Vite Env Types]]
- [[_COMMUNITY_NormalizedError|NormalizedError]]
- [[_COMMUNITY_ExamSession|ExamSession]]
- [[_COMMUNITY_SentinelProfile|SentinelProfile]]
- [[_COMMUNITY_WebsocketPayloads|WebsocketPayloads]]

## God Nodes (most connected - your core abstractions)
1. `KeycloakStore (Pinia)` - 9 edges
2. `User service (current user, settings, roles)` - 8 edges
3. `main.ts (app bootstrap)` - 7 edges
4. `GraphQL client (villus) with Keycloak auth plugin` - 7 edges
5. `ExamDetailView` - 7 edges
6. `Proctor README Overview` - 6 edges
7. `Exams service (GraphQL CRUD + start/end via pinia-colada)` - 6 edges
8. `Notices service (GraphQL CRUD for admin notices)` - 6 edges
9. `HomeView` - 6 edges
10. `Proctor Cleanup Plan` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Proctor index.html Entry` --conceptually_related_to--> `Proctor README Overview`  [INFERRED]
  proctor/index.html → proctor/README.md
- `ConfirmDialog` --semantically_similar_to--> `NewExamDialog`  [INFERRED] [semantically similar]
  proctor/src/components/ConfirmDialog.vue → proctor/src/components/NewExamDialog.vue
- `ExamRow` --conceptually_related_to--> `ExamStatusFilter`  [INFERRED]
  proctor/src/components/ExamRow.vue → proctor/src/components/ExamStatusFilter.vue
- `English locale` --semantically_similar_to--> `German locale`  [INFERRED] [semantically similar]
  proctor/src/locales/en.json → proctor/src/locales/de.json
- `dismissedNotices service (localStorage-backed notice dismissal)` --conceptually_related_to--> `Notices service (GraphQL CRUD for admin notices)`  [INFERRED]
  proctor/src/services/dismissedNotices.ts → proctor/src/services/notices.ts

## Hyperedges (group relationships)
- **MVVM Data Stack (View → Composable → Villus → Pinia Colada → GraphQL)** — proctor_agents_mvvm_dataflow, proctor_rewrite_villus, proctor_rewrite_pinia_colada, proctor_rewrite_graphql_backend [EXTRACTED 1.00]
- **Franklyn Workspaces** — proctor_readme_overview, proctor_rewrite_sentinel, proctor_rewrite_graphql_backend, proctor_rewrite_ws_gateway [EXTRACTED 1.00]
- **Phase 5 Router Refactor Trio** — continuation_phase5_handoff, proctor_agents_useroles, proctor_rewrite_phase5 [EXTRACTED 1.00]
- **Dialog-based components** — components_confirmdialog, components_newexamdialog, ui_dialog [EXTRACTED 1.00]
- **UI primitive components** — ui_button, ui_dialog, ui_dropdownselect, ui_icon, ui_themeswitcher [EXTRACTED 1.00]
- **Exam-related components** — components_examrow, components_examstatusfilter, components_newexamdialog [EXTRACTED 1.00]
- **Services using GraphQL via villus** — services_exams, services_notices, services_sessions, services_user, services_graphql [EXTRACTED 1.00]
- **Pinia stores** — stores_keycloakstore, stores_themestore [EXTRACTED 1.00]
- **i18n locales setup** — src_i18n, locales_en, locales_de [EXTRACTED 1.00]
- **All views** — views_adminnoticebannersview, views_examdetailview, views_homeview, views_notallowedview, views_proctoringview, views_settingsview [EXTRACTED 1.00]
- **Websocket payload types** — types_websocketpayloads_proctormessage, types_websocketpayloads_servermessage, types_websocketpayloads_registermessage, types_websocketpayloads_sentinelidmessage, types_websocketpayloads_setprofilemessage, types_websocketpayloads_subscribepinmessage, types_websocketpayloads_acknowledgmentmessage, types_websocketpayloads_rejection, types_websocketpayloads_sentinelinfo, types_websocketpayloads_updatesentinelsmessage, types_websocketpayloads_framemessage, types_websocketpayloads_frame [EXTRACTED 1.00]
- **Exam domain types** — types_exam, types_notice, types_user [EXTRACTED 1.00]

## Communities (37 total, 6 thin omitted)

### Community 0 - "Exam List UI & Status"
Cohesion: 0.24
Nodes (15): ConfirmDialog, ExamRow, ExamStatusFilter, NewExamDialog, datetime helpers, examStatus helpers, German locale, English locale (+7 more)

### Community 1 - "App Bootstrap & Auth Wiring"
Cohesion: 0.21
Nodes (13): NavComponent, Vue Router setup with auth guard, Theme service (initTheme + useResolvedTheme), User service (current user, settings, roles), useRoles(), main.ts (app bootstrap), KeycloakStore (Pinia), ThemeStore (Pinia, persisted) (+5 more)

### Community 2 - "Live Proctoring & WebSocket Protocol"
Cohesion: 0.15
Nodes (15): ExpandedSentinelOverlay, WebsocketStore, AcknowledgmentMessage, Frame, FrameMessage, ProctorMessage, RegisterMessage, Rejection (+7 more)

### Community 3 - "Project Docs & Decisions"
Cohesion: 0.23
Nodes (12): Phase 5 Handoff Document, Phase 6 Handoff Document, Proctor Agent Conventions, WebSocket / Protobuf Wire Format Decision, Proctor index.html Entry, Proctor README Overview, Proctor Cleanup Plan, Protobuf Kept Wired but Unused (+4 more)

### Community 4 - "Migration Phases & Rules"
Cohesion: 0.24
Nodes (11): i18n Rule (t/d, en+de in sync), CSS Custom Property Styling Rule, Two-Layer Cache (Villus + Pinia Colada), Apollo Client Removal, Drop de_at Locale Decision, Phase 0 — Foundation, Phase 1 — Tokens and Shared CSS, Phase 2 — i18n Completeness (+3 more)

### Community 5 - "GraphQL Services & Data Layer"
Cohesion: 0.29
Nodes (10): dismissedNotices service (localStorage-backed notice dismissal), Exams service (GraphQL CRUD + start/end via pinia-colada), GraphQL client (villus) with Keycloak auth plugin, executeMutation(), executeQuery(), Notices service (GraphQL CRUD for admin notices), Sessions service (GraphQL allStudents query), Notice (+2 more)

### Community 6 - "Auth, Theme & Cleanup Phases"
Cohesion: 0.20
Nodes (10): useRoles Composable, Theme Resolution Rule (backend wins), Keycloak Authentication, Keycloak Stored-Session Race Bug, Phase 4 — Per-store and Per-view Cleanup, Phase 5 — Router, Phase 6 — Component Library Skeleton, Phase 7 — Final Pass (+2 more)

### Community 8 - "Domain Types (User/Theme/Role)"
Cohesion: 0.67
Nodes (3): Theme type ('LIGHT'|'DARK'|'SYSTEM'), User, UserRole

## Knowledge Gaps
- **26 isolated node(s):** `Proctor index.html Entry`, `Phase 0 — Foundation`, `Phase 7 — Final Pass`, `Reka UI Primitives`, `Keycloak Stored-Session Race Bug` (+21 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WebsocketStore` connect `Live Proctoring & WebSocket Protocol` to `App Bootstrap & Auth Wiring`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **Why does `KeycloakStore (Pinia)` connect `App Bootstrap & Auth Wiring` to `Live Proctoring & WebSocket Protocol`, `GraphQL Services & Data Layer`?**
  _High betweenness centrality (0.063) - this node is a cross-community bridge._
- **Why does `Phase 5 — Router` connect `Auth, Theme & Cleanup Phases` to `Project Docs & Decisions`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **What connects `MVVM Data Flow Rule`, `CSS Custom Property Styling Rule`, `i18n Rule (t/d, en+de in sync)` to the rest of the system?**
  _35 weakly-connected nodes found - possible documentation gaps or missing edges._
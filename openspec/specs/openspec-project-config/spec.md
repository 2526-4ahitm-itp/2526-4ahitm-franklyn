### Requirement: Config contains project context
`openspec/config.yaml` SHALL contain a `context` block describing the tech stack, domain vocabulary, and role definitions so that AI artifact generation has full project knowledge.

#### Scenario: Context block present
- **WHEN** `openspec/config.yaml` is read
- **THEN** it contains `context:` with tech stack (Java/Quarkus, Vue.js, Rust, PostgreSQL, Keycloak), domain terms (Exam, Sentinel, Proctor, Session, Violation, Alarm), and roles (Schüler, Lehrer, Admin)

### Requirement: Config contains per-artifact rules
`openspec/config.yaml` SHALL contain a `rules` block with constraints for `proposal`, `specs`, and `tasks` artifact types.

#### Scenario: Rules block present
- **WHEN** `openspec/config.yaml` is read
- **THEN** `rules.proposal` requires FSD section references, `rules.specs` requires implementation status per requirement, and `rules.tasks` requires `[GAP]` / `[SPEC]` labels

### Requirement: Specs note implementation status
Every requirement in every spec file SHALL include an implementation status marker: `implemented`, `partial`, or `not-implemented`.

#### Scenario: Requirement has status
- **WHEN** a spec requirement is written
- **THEN** it includes one of the three status markers so gap analysis is immediately visible

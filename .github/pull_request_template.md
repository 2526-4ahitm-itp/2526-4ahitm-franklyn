## Summary

<!-- Explain the motivation for this change. What problem does it solve? Link to related issues. -->

Fixes #

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update
- [ ] Other (please describe):

## Checklist

- [ ] I have performed a self-review of my code
- [ ] I have run the tests using the dedicated test scripts
- [ ] I have updated the documentation (if applicable)
- [ ] I have verified that my changes work correctly:
  - [ ] **Server (GraphQL API):** I have tested affected queries/mutations using the [Bruno](https://www.usebruno.com/) collection (`server/http/franklyn/`) or the GraphQL Dev UI (`/q/graphql-ui`) and confirmed correct responses
  - [ ] **Server (WebSocket):** If WebSocket behavior was changed, I have verified real-time communication between Sentinel and Proctor works as expected
  - [ ] **Proctor (Frontend):** I have manually tested the affected UI in the browser, clicked through relevant flows, and confirmed the feature/fix works visually and functionally
  - [ ] **Sentinel / iOS:** I have run the respective client and confirmed it behaves correctly against the server
  - [ ] **End-to-end:** For user-facing features, I have tested the full flow from the UI (or client) through the API to the database and back
  - [ ] **N/A** — my change does not affect runtime behavior (e.g., docs-only, refactoring with existing test coverage)

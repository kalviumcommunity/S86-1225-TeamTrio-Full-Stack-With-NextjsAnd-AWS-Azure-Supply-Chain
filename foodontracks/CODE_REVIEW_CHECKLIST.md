# Code Review Checklist ✅

Before approving a PR, confirm the following. Use the checklist as a guide and leave precise comments when you request changes.

## PR basics
- [ ] **Branch name** follows the team's convention (feature/, fix/, chore/, etc.)
- [ ] **PR title & description** clearly explain the change, why it's needed, and how to test it
- [ ] **Related issues / ticket IDs** are referenced in the PR
- [ ] **Scope** is focused: PRs should be small and limited to a single concern

## Code quality & style
- [ ] Code is readable, idiomatic, and commented where necessary
- [ ] No leftover console.log, debugger statements, or commented-out debug code
- [ ] Linting and formatting pass (ESLint / Prettier)
- [ ] No unnecessary or unused files are added

## Testing
- [ ] Unit tests added or updated for new logic
- [ ] Integration / end-to-end tests added where appropriate
- [ ] All tests pass locally and in CI
- [ ] Edge cases and error paths are covered

## Security & secrets
- [ ] No secrets, API keys, or credentials in code or committed files
- [ ] No sensitive environment variables exposed to the client (NEXT_PUBLIC_ rules)
- [ ] Input validation and authorization checks are present where needed

## Performance & scalability
- [ ] No obvious performance regressions (N+1 queries, excessive loops, unbounded memory usage)
- [ ] Database queries are indexed appropriately for new lookups

## Database & migrations
- [ ] Migration files are present for schema changes and reviewed for destructive operations
- [ ] Migration steps are tested locally (migrate / reset + seed) or a rollback plan is documented
- [ ] Seed data is idempotent and safe to run multiple times

## Documentation & observability
- [ ] README/docs updated when behavior or API changes
- [ ] Add or update API contract docs, Postman/Swagger, or GraphQL schema docs
- [ ] Logging & monitoring added/updated for important events or failures

## Release & deployment
- [ ] Feature flags (if required) are present and documented
- [ ] Migration and deploy order is documented if required
- [ ] Rollback / mitigation plan included for risky changes

## Visuals & accessibility
- [ ] Screenshots or recording for visual changes are attached
- [ ] Accessibility considerations checked (keyboard nav, ARIA, color contrast)

## Final checks
- [ ] CI checks pass on PR
- [ ] At least one approved reviewer (and security/product sign-off if required)
- [ ] PR linked to the release/roadmap ticket if needed

---

## PR Template (copy to `.github/PULL_REQUEST_TEMPLATE.md` or use in PR description)

Title: [type] Short, imperative description (e.g. feat: add user onboarding flow)

Description:
- What changed and why
- What side effects or trade-offs to be aware of

Testing steps:
1. Step one to reproduce or test
2. Step two...

Checklist:
- [ ] Branch name follows convention
- [ ] Tests added / updated
- [ ] Docs updated
- [ ] Migration included (if applicable)
- [ ] Screenshots attached (if UI)

Notes (optional):
- Rollback plan or special deployment notes

---

If you'd like, I can add the PR template as an actual file at `.github/PULL_REQUEST_TEMPLATE.md`. Let me know and I'll create it for you.
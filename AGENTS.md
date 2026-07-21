# Agent Notes

This file records collaboration rules for agents working in this repository.

## Change Documentation

Every agent-made repository change must leave a short documentation record.

- Write the record in `docs/CHANGELOG.md` by default.
- If a change is better documented in a more specific file, update that file and mention it in `docs/CHANGELOG.md`.
- Include the date, changed area, a concise summary, and any verification that was run.
- Keep entries factual and brief. Do not rewrite unrelated history.
- Pure investigation or question-answering does not need a changelog entry unless it changes files.

When editing runtime behavior, also update user-facing or agent-facing docs when the behavior, commands, install flow, troubleshooting path, or known limitations change.

## Public Release and Push Safety

This is a public repository. Treat every push as a public release of all commits that are ahead of the remote branch.

Before every push:

1. Update the public `README.md` "更新记录" section with the current date and a concise user-facing summary. Update the existing entry when pushing more changes on the same date.
2. Update `docs/CHANGELOG.md` with the detailed change and verification record. A changelog entry alone does not replace the README update record.
3. Review `git status`, the complete staged diff, and every commit that will be pushed—not only the latest commit. Confirm that all files and commits belong to the intended public change.
4. Scan tracked files, staged changes, and commits ahead of the remote for secrets and sensitive data. Check for API keys, access tokens, passwords, private keys, certificates, cookies, authorization headers, connection strings, `.env` files, credential files, private logs, debug dumps, and machine-specific personal data.
5. Use placeholders in examples. Never commit real credentials or copy secret-bearing command output into documentation, tests, changelogs, or learning records.
6. If any suspected secret is found, stop the push. Remove it from every commit that would be published and rotate/revoke the credential when exposure is possible; deleting it only from the newest file version is insufficient.
7. Run `git diff --check` and the relevant tests before pushing. Push only after the documentation, scope, secret review, and verification checks pass.

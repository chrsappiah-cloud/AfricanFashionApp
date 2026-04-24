# Enforcing CI on GitHub

Use a **ruleset** (Settings → Code and automation → Rules → Rulesets) or classic branch protection for **`main`**.

1. **Require a pull request before merging** (recommended).
2. Under **Require status checks to pass**, require the check named **`ios`** (job id in `.github/workflows/ios-ci-cd.yml`). It appears as **iOS CI/CD / ios** in the PR checks list.
3. Optionally enable **Require branches to be up to date before merging**.

If **`ios`** does not appear, push to **`main`** once so Actions runs, then pick the check from the list.

GitHub Actions integration id **`15368`** is used when configuring required checks via the API (same as other repositories using GitHub-hosted runners).

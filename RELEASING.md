# Releasing

Releases are created by pushing a semver tag to `main`. CI picks it up, packages the addon, and publishes a GitHub release automatically.

## Steps

1. Make sure `main` is in a releasable state (all PRs merged, no broken builds).

2. Tag the commit:
   ```bash
   git checkout main
   git pull
   git tag 1.9.0
   git push origin 1.9.0
   ```

3. The `Package World of Warcraft addon` workflow triggers automatically. It will:
   - Run `package.sh 1.9.0` to stage and zip the addon
   - Substitute `@project-version@` → `1.9.0` in the packaged files
   - Create a GitHub release tagged `Gratwurst-release-v1.9.0` with the zip attached

4. Verify the release at `https://github.com/bitobrian/Gratwurst/releases`.

## Version format

Tags must be `X.Y.Z` (semver). Examples: `1.9.0`, `2.0.0`, `1.9.1`.  
Anything that doesn't start with a digit will not trigger the workflow.  
Manual `workflow_dispatch` runs enforce the same `X.Y.Z` format.

## Manual release (without a tag)

If you need to re-run packaging without pushing a new tag, trigger the workflow manually from the GitHub Actions UI and enter the version number (e.g. `1.9.0`).

## Notes

- The `@project-version@` token in source files is **never** replaced in the working tree — only in the packaged output. Dev builds installed via `dev.ps1` use `0.0.0.0` as the version.
- To package locally, run: `.\package.ps1 1.9.0` (Windows) or `bash package.sh 1.9.0` (Linux/macOS).

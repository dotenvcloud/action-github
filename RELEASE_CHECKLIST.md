# Release Checklist

Before releasing a new version of the DotEnv GitHub Action, ensure all items are completed:

## Pre-Release

### Code Quality
- [ ] All tests pass in CI
- [ ] No security vulnerabilities identified
- [ ] Code reviewed by at least one other person
- [ ] Input validation is comprehensive
- [ ] Error messages are clear and helpful

### Documentation
- [ ] README.md is up to date
- [ ] CHANGELOG.md updated with new changes
- [ ] Version number updated in VERSION file
- [ ] All examples use correct repository reference

### Security
- [ ] API keys are properly masked in all scenarios
- [ ] No sensitive data is logged
- [ ] Checksum verification is working (when available)
- [ ] All inputs are validated against injection

### Compatibility
- [ ] Tested on Ubuntu runners
- [ ] Tested on macOS runners
- [ ] Tested on Windows runners
- [ ] Works with latest GitHub Actions features

## Release Process

1. **Update Version**
   ```bash
   # Update VERSION file
   echo "1.0.1" > VERSION
   
   # Update CHANGELOG.md with release date
   # Update any version references in README.md
   ```

2. **Create Git Tag**
   ```bash
   git add -A
   git commit -m "chore: release v1.0.1"
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin main
   git push origin v1.0.1
   ```

3. **Update Major Version Tag**
   ```bash
   git tag -fa v1 -m "Update v1 tag"
   git push origin v1 --force
   ```

4. **Create GitHub Release**
   - Go to GitHub releases page
   - Click "Draft a new release"
   - Select the version tag
   - Use the CHANGELOG content for description
   - Publish release

5. **Publish to Marketplace** (if public)
   - During release creation, check "Publish this Action to the GitHub Marketplace"
   - Select appropriate categories
   - Add icon and color in action.yml

## Post-Release

- [ ] Verify action works by creating a test workflow
- [ ] Monitor issues for any problems
- [ ] Update internal documentation if needed
- [ ] Announce release if appropriate

## Rollback Plan

If issues are discovered:

1. **Delete problematic release**
   ```bash
   git push --delete origin v1.0.1
   ```

2. **Move major version tag back**
   ```bash
   git tag -fa v1 v1.0.0 -m "Rollback v1 tag"
   git push origin v1 --force
   ```

3. **Fix issues and re-release**
   - Create new patch version
   - Follow release process again

## Notes

- Always test in a separate repository before releasing
- Consider using release candidates (v1.0.1-rc1) for major changes
- Keep the CLI compatibility matrix updated
- Monitor dotenv/cli releases for compatibility
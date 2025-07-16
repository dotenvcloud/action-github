# Repository Management Guide

This GitHub Action is maintained as a separate git repository within the dotenv-workspace.

## Current Setup

- **Local Path**: `/actions/github-action/`
- **Remote Origin**: `git@github.com:lostlink/dotenv-action-github.git`
- **Initial Commit**: Created with all action files

## Important: Repository Visibility

**The repository at `lostlink/dotenv-action-github` MUST be PUBLIC** for the following reasons:

1. **GitHub Marketplace**: Only public repositories can be published to the GitHub Marketplace
2. **Action Usage**: Users need to access the action code when using `uses: lostlink/dotenv-action-github@v1`
3. **Community**: Allows community contributions and issue tracking
4. **Trust**: Users can inspect the code for security audits

## Working with the Repository

### Initial Push
```bash
cd /Users/nsouto/Sites/Valet/dotenv-workspace/actions/github-action
git push -u origin main
```

### Making Changes
```bash
cd /Users/nsouto/Sites/Valet/dotenv-workspace/actions/github-action

# Make your changes
# ...

# Commit changes
git add .
git commit -m "feat: your feature description"

# Push to GitHub
git push
```

### Tagging Releases
```bash
# Create a release tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# For the marketplace, also create a major version tag
git tag -fa v1 -m "Update v1 tag"
git push origin v1 --force
```

## Publishing to GitHub Marketplace

1. Make the repository public on GitHub
2. Go to the repository's main page
3. Click on "Releases" → "Draft a new release"
4. Choose your tag (e.g., v1.0.0)
5. Click "Publish this Action to the GitHub Marketplace"
6. Fill in the required categories and information
7. Publish the release

## Version Management

Users will reference the action in three ways:
- `uses: lostlink/dotenv-action-github@v1` (recommended - follows major version)
- `uses: lostlink/dotenv-action-github@v1.0.0` (pins to specific version)
- `uses: lostlink/dotenv-action-github@main` (not recommended - uses latest code)

Always maintain backward compatibility within major versions.

## Repository Structure

This repository is excluded from the main dotenv-workspace git tracking via `.gitignore`, allowing it to maintain its own git history and remote.
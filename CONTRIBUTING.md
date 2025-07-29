# Contributing to DotEnv GitHub Action

Thank you for your interest in contributing to the DotEnv GitHub Action! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/dotenv-action.git
   cd dotenv-action
   ```
3. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites

- Git
- A GitHub account
- Basic knowledge of GitHub Actions
- (Optional) The DotEnv CLI for testing

### Testing Locally

You can test the action locally using [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # macOS
# or see https://github.com/nektos/act#installation for other platforms

# Run tests
act -j test-action
```

### Testing with Real API

To test with a real DotEnv API:

1. Create a test project in your DotEnv account
2. Generate an API key
3. Set up secrets in your fork:
   - `DOTENV_TEST_API_KEY`: Your test API key
   - `DOTENV_TEST_PROJECT`: Your test project name

## Making Changes

### Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Keep scripts POSIX-compliant for maximum compatibility
- Test on multiple platforms (Linux, macOS, Windows)

### Commit Messages

We follow conventional commits:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or modifications
- `chore:` Maintenance tasks

Examples:
```
feat: add support for custom CLI versions
fix: handle spaces in project names
docs: update README with new examples
```

### Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the test workflow if you've added new functionality
3. Ensure all tests pass
4. Update the action version in examples if needed
5. Submit a pull request with a clear description

### Pull Request Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested locally with act
- [ ] Tested on GitHub Actions
- [ ] Added new tests

## Checklist
- [ ] My code follows the project style
- [ ] I've updated documentation as needed
- [ ] All tests pass
- [ ] I've tested on multiple OS platforms
```

## Testing

### Running Tests

```bash
# Run the test workflow
act -j test-action

# Run specific job
act -j test-install

# Run with specific OS
act -j test-install --matrix os:ubuntu-latest
```

### Adding Tests

When adding new features, please include tests in `.github/workflows/test.yml`:

```yaml
- name: Test new feature
  uses: ./
  with:
    api-key: ${{ secrets.DOTENV_TEST_API_KEY }}
    project: test-project
    your-new-input: value
```

## Reporting Issues

### Security Issues

For security vulnerabilities, please email security@dotenv.cloud instead of using the issue tracker.

### Bug Reports

Please include:
- Action version
- GitHub Actions runner OS
- Relevant workflow configuration
- Error messages
- Steps to reproduce

### Feature Requests

We welcome feature requests! Please include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Additional context

## Documentation

- Update README.md for user-facing changes
- Add JSDoc-style comments for complex functions
- Include examples for new features
- Keep documentation concise and clear

## Release Process

Releases are managed by the maintainers:

1. Update version in action.yml metadata
2. Update CHANGELOG.md
3. Create GitHub release with tag
4. Update GitHub Marketplace listing

## Questions?

Feel free to:
- Open an issue for questions
- Join our [Discord community](https://discord.gg/dotenv)
- Email support@dotenv.cloud

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
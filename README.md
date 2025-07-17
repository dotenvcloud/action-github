# DotEnv GitHub Action

<div align="center">
  <img src="https://dotenv.com/logo.svg" alt="DotEnv Logo" width="200">
  
  [![GitHub release](https://img.shields.io/github/release/lostlink/dotenv-action-github.svg)](https://github.com/lostlink/dotenv-action-github/releases)
  [![License](https://img.shields.io/github/license/lostlink/dotenv-action-github)](LICENSE)
  [![GitHub marketplace](https://img.shields.io/badge/marketplace-dotenv--action-blue?logo=github)](https://github.com/marketplace/actions/dotenv-secrets)
</div>

<p align="center">
  <strong>Securely pull environment variables from DotEnv platform in your GitHub Actions workflows</strong>
</p>

---

## 🚀 Quick Start

```yaml
- name: Pull secrets
  uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    target: production
```

## 📋 Prerequisites

1. A DotEnv account ([sign up here](https://dotenv.cloud))
2. An API key (generate in your DotEnv dashboard)
3. A project with secrets configured

## 🔧 Setup

### 1. Add your API key to GitHub Secrets

1. Go to your repository's Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `DOTENV_API_KEY`
4. Value: Your DotEnv API key

### 2. Add the action to your workflow

```yaml
name: Deploy
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Pull DotEnv secrets
        uses: lostlink/dotenv-action-github@v1
        with:
          api-key: ${{ secrets.DOTENV_API_KEY }}
          project: myapp
          target: production
      
      - name: Use secrets
        run: |
          # Your secrets are now available as environment variables
          echo "API URL is set: $API_URL"
```

## 📖 Usage Examples

### Basic Usage

Pull all secrets for a project:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
```

### With Target Environment

Pull secrets for a specific target (e.g., production, staging):

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    target: production
```

### Full Hierarchy

Pull secrets for project/target/environment:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    target: production
    environment: api
```

### Export as Environment Variables

Export secrets as GitHub environment variables for subsequent steps:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    target: production
    export-variables: true

- name: Use exported variables
  run: |
    echo "Database URL: $DATABASE_URL"
    echo "API Key is available: $API_KEY"
```

### Different Output Formats

Export in JSON format:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    format: json
    output-file: secrets.json
```

Available formats: `env`, `json`, `yaml`, `shell`, `dockerfile`

### Custom Output Location

Write to a specific file:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    output-file: config/.env.production
```

### Variable Interpolation

Resolve variable references:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    resolve: true
```

This will resolve variables like:
```
BASE_URL=https://api.example.com
API_ENDPOINT=${BASE_URL}/v1
```

### Organization Override

Use a different organization:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    organization: my-other-org
```

### Custom API URL

For enterprise or testing:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    api-url: https://dotenv.enterprise.com
```

### Specific CLI Version

Use a specific version of the DotEnv CLI:

```yaml
- uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    cli-version: '1.2.3'
```

## 🔑 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-key` | DotEnv API key for authentication | ✅ | - |
| `project` | Project name to pull secrets from | ✅ | - |
| `target` | Target environment (e.g., production, staging) | ❌ | - |
| `environment` | Specific environment within target | ❌ | - |
| `output-file` | Path to write the .env file | ❌ | `.env` |
| `format` | Output format (env, json, yaml, shell, dockerfile) | ❌ | `env` |
| `export-variables` | Export secrets as GitHub environment variables | ❌ | `false` |
| `organization` | Organization to use | ❌ | - |
| `api-url` | Custom API URL | ❌ | - |
| `decrypt` | Decrypt secrets | ❌ | `true` |
| `resolve` | Resolve variable interpolation | ❌ | `false` |
| `quiet` | Suppress output | ❌ | `false` |
| `merge` | Merge secrets from all hierarchy levels | ❌ | `true` |
| `cli-version` | Specific CLI version to use | ❌ | `latest` |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `env-file` | Path to the generated environment file |

## 🏗️ Complete Workflow Examples

### Node.js Application

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Pull secrets
        uses: lostlink/dotenv-action-github@v1
        with:
          api-key: ${{ secrets.DOTENV_API_KEY }}
          project: myapp
          target: production
          export-variables: true
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
        env:
          # Secrets are available as environment variables
          NODE_ENV: production
      
      - name: Deploy
        run: npm run deploy
```

### Docker Build

```yaml
name: Docker Build
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Pull secrets for Docker
        uses: lostlink/dotenv-action-github@v1
        with:
          api-key: ${{ secrets.DOTENV_API_KEY }}
          project: myapp
          target: production
          format: dockerfile
          output-file: .env.docker
      
      - name: Build Docker image
        run: |
          docker build --env-file .env.docker -t myapp:latest .
```

### Multi-Environment Deployment

```yaml
name: Deploy to Multiple Environments
on:
  push:
    branches: [main, staging]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Determine environment
        id: env
        run: |
          if [ "${{ github.ref }}" == "refs/heads/main" ]; then
            echo "target=production" >> $GITHUB_OUTPUT
          else
            echo "target=staging" >> $GITHUB_OUTPUT
          fi
      
      - name: Pull environment-specific secrets
        uses: lostlink/dotenv-action-github@v1
        with:
          api-key: ${{ secrets.DOTENV_API_KEY }}
          project: myapp
          target: ${{ steps.env.outputs.target }}
          export-variables: true
      
      - name: Deploy
        run: |
          echo "Deploying to ${{ steps.env.outputs.target }}"
          ./deploy.sh
```

## 🔒 Security Best Practices

### API Key Management
1. **Never commit your API key** - Always use GitHub Secrets
2. **Use least privilege** - Create API keys with minimal required permissions
3. **Rotate keys regularly** - Update your API keys periodically
4. **Use organization-specific keys** - Don't share API keys across organizations

### Action Security
1. **Pin to specific versions** - Use `@v1.0.0` instead of `@v1` for production
2. **Review action code** - This action is open source, review the code before use
3. **Limit workflow permissions** - Use minimal GitHub token permissions:
   ```yaml
   permissions:
     contents: read  # Only if needed
   ```

### Secret Protection
1. **Automatic masking** - The action masks your API key and secret values in logs
2. **Use specific targets** - Pull only the secrets you need for each environment
3. **Avoid debug mode** - Don't enable debug logging in production workflows
4. **Clean up files** - Remove `.env` files after use in CI/CD:
   ```yaml
   - name: Clean up
     if: always()
     run: rm -f .env
   ```

### Input Validation
The action validates all inputs to prevent injection attacks:
- Project/target/environment names must contain only alphanumeric characters, dash, underscore, and dot
- Maximum length of 100 characters per name
- No path traversal patterns allowed

### Network Security
1. **HTTPS only** - All API communications use HTTPS
2. **Checksum verification** - CLI downloads are verified when checksums are available
3. **GitHub token for downloads** - Uses GitHub token to avoid rate limits

## 🧪 Testing Locally

You can test the action locally using [act](https://github.com/nektos/act):

```bash
act -s DOTENV_API_KEY=your-api-key
```

## 🐛 Troubleshooting

### Authentication Failed

```
Error: Authentication failed
```

**Solution**: Verify your API key is correct and has the necessary permissions.

### Project Not Found

```
Error: Project 'myapp' not found
```

**Solution**: Ensure the project exists and your API key has access to it.

### No Secrets Found

```
Warning: No secrets found for myapp/production
```

**Solution**: Check that secrets are configured for the specified hierarchy level.

### CLI Installation Failed

```
Error: Failed to install DotEnv CLI
```

**Solution**: Check your GitHub Actions runner has internet access. Try specifying a specific CLI version.

### Windows Runners

The action works on Windows runners, but uses bash shell for all operations. GitHub-hosted Windows runners include Git Bash. For self-hosted Windows runners, ensure Git Bash is installed.

### Invalid Input Characters

```
Error: Project name contains invalid characters
```

**Solution**: Use only alphanumeric characters, dash, underscore, and dot in project/target/environment names.

## 📝 Advanced Configuration

### Using with Matrix Builds

```yaml
strategy:
  matrix:
    environment: [staging, production]
    region: [us-east-1, eu-west-1]

steps:
  - uses: lostlink/dotenv-action-github@v1
    with:
      api-key: ${{ secrets.DOTENV_API_KEY }}
      project: myapp
      target: ${{ matrix.environment }}
      environment: ${{ matrix.region }}
```

### Conditional Secret Loading

```yaml
- name: Pull secrets (if not PR)
  if: github.event_name != 'pull_request'
  uses: lostlink/dotenv-action-github@v1
  with:
    api-key: ${{ secrets.DOTENV_API_KEY }}
    project: myapp
    target: production
```

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [DotEnv Platform](https://dotenv.com)
- [DotEnv CLI](https://github.com/dotenv/cli)
- [Documentation](https://dotenv.com/docs)
- [Support](https://dotenv.com/support)

## 💬 Support

- 📧 Email: support@dotenv.com
- 💬 Discord: [Join our community](https://discord.gg/dotenv)
- 🐛 Issues: [GitHub Issues](https://github.com/lostlink/dotenv-action-github/issues)

---

<p align="center">
  Made with ❤️ by the <a href="https://dotenv.com">DotEnv</a> team
</p>
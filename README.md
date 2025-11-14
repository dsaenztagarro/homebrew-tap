# Personal Homebrew Tap

A custom Homebrew tap for managing version-controlled development tools and dependencies.

## What is this repository for?

This repository serves as my personal, version-controlled package manager for critical development tools. By maintaining my own Homebrew tap, I ensure:

- **Version Control**: Lock specific versions of critical tools (OpenSSL, PostgreSQL, AWS CLI, Redis, etc.)
- **Consistent Development Environments**: Eliminate "works on my machine" issues caused by version drift
- **Security & Compliance**: Audit and validate all packages before adoption
- **Build Reproducibility**: Ensure CI/CD environments match local development setups exactly
- **Disaster Recovery**: Maintain internal copies of critical dependencies, surviving upstream changes or deprecations

## Usage

### Installing the Tap

```bash
# 1. Tap the repository
brew tap dsaenztagarro/tap

# 2. Install packages from the tap
brew install dsaenztagarro/tap/ca-certificates
brew install dsaenztagarro/tap/openssl@3
brew install dsaenztagarro/tap/postgresql@14
brew install dsaenztagarro/tap/redis@7
brew install dsaenztagarro/tap/awscli

# 3. Verify installation
brew list --versions | grep dsaenztagarro
```

### For Fresh Installation

```bash
# Quick setup script (if available)
./scripts/setup-homebrew.sh

# Or manually install core packages
brew tap dsaenztagarro/tap
brew install dsaenztagarro/tap/ca-certificates
brew install dsaenztagarro/tap/openssl@3
brew install dsaenztagarro/tap/postgresql@14
brew install dsaenztagarro/tap/redis@7
brew install dsaenztagarro/tap/awscli
```

### Updating Packages

```bash
# Update tap formulas
brew update

# Upgrade a specific package
brew upgrade dsaenztagarro/tap/openssl@3

# Check for available updates
brew outdated
```

## Reasons to Adopt

### Key Benefits

1. **Dependency Version Control**
   - Lock specific versions of critical tools
   - Prevent version drift across environments
   - Enable deterministic development environments

2. **Security & Compliance**
   - Audit and validate packages before adoption
   - Quickly patch or rollback problematic versions
   - Track exactly which versions have been vetted

3. **Build Reproducibility**
   - Ensure CI/CD environments match local setups
   - Reduce build failures due to upstream package changes
   - Pin formula commits to specific, tested versions

4. **Disaster Recovery**
   - Survive upstream formula deletions or breaking changes
   - Maintain internal copies of critical dependencies
   - Quick recovery when Homebrew core formulas are deprecated

5. **Engineering Excellence**
   - Maintain professional-grade tooling practices
   - Reduce setup time and troubleshooting
   - Standardized tooling across all projects

## Industry Adoption

### Industry Leaders Using Custom Taps

Several major technology companies maintain custom Homebrew taps for their engineering teams:

- **GitHub**: Maintains internal Homebrew taps for engineering tooling
- **Shopify**: Uses custom taps for development tools ([Shopify/homebrew-shopify](https://github.com/Shopify/homebrew-shopify))
- **Stripe**: Maintains internal formula repositories for payment infrastructure tools
- **HashiCorp**: Publishes official taps ([hashicorp/homebrew-tap](https://github.com/hashicorp/homebrew-tap))
- **Microsoft**: Distributes enterprise tools via custom taps ([microsoft/homebrew-mssql-release](https://github.com/microsoft/homebrew-mssql-release))
- **AWS**: Uses custom taps for AWS CLI and SDK tools ([aws/homebrew-tap](https://github.com/aws/homebrew-tap))

This practice follows the same professional standards used by industry leaders.

## Available Formulas

| Formula | Description | Current Version |
|---------|-------------|-----------------|
| `ca-certificates` | Mozilla CA certificate store | 2025-11-04 |

_More formulas will be added as the tap matures. See the [Formula/](Formula/) directory for all available packages._

## Maintenance Philosophy

This tap is maintained as part of my personal engineering excellence practice:

- **Version Control**: All formulas are versioned and tracked
- **Security**: Regular monitoring for CVE updates
- **Testing**: Formulas are tested before addition
- **Documentation**: Clear documentation for all decisions

## Resources

- [Homebrew Documentation](https://docs.brew.sh/)
- [How to Create a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [brew extract Documentation](https://docs.brew.sh/Manpage#extract-options-formula-tap)

---

**Maintained by**: David Saenz Tagarro  
**Last Updated**: 2025-11-14  
**Purpose**: Personal engineering excellence practice

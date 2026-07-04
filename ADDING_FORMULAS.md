# Adding New Formulas to This Tap

This guide explains how to add new formulas to this personal Homebrew tap.

## Table of Contents

- [Versioning Strategy](#versioning-strategy)
- [Understanding Tap Repository Locations](#understanding-tap-repository-locations)
- [Prerequisites](#prerequisites)
- [Method 1: Using `brew extract` (Recommended)](#method-1-using-brew-extract-recommended)
- [Method 2: Manual Formula Creation](#method-2-manual-formula-creation)
- [Formula Validation](#formula-validation)
- [Testing the Formula](#testing-the-formula)
- [Committing the Formula](#committing-the-formula)
- [Decision Framework](#decision-framework)

---

## Versioning Strategy

**Important:** Before adding a formula, decide how it should be named and versioned.
Read **[docs/VERSIONING_STRATEGY.md](docs/VERSIONING_STRATEGY.md)** first — the short
version is below.

This tap names formulas for their **purpose/identity**, not with a homebrew-core-style
`@X.Y` filename + `Aliases/` scheme. A formula's version lives in its `.rb` file
(`url` + `sha256`); `brew` installs from HEAD of the default branch, so there are **no git
tags, no `CHANGELOG`, and no `Aliases/` directory**.

- **Purpose-named formulas** (the default here). Name for the job — e.g. `openssl-ruby`
  is an isolated OpenSSL for building Ruby, deliberately **not** named `openssl@3.5`, so it
  never matches ruby-build's `^openssl@` auto-detection. Patch updates are edited in place
  (no rename). If `brew extract` produces a patch-versioned file like `openssl@3.5.4.rb`,
  rename it to the purpose name and set the class accordingly.
- **cargo-dist binary formulas** (e.g. `engineer`). Generated and pushed by cargo-dist at
  release; don't hand-edit. They carry a `BINARY_ALIASES` constant, which CI uses to skip
  the source-build audit/install.
- **General-purpose versioned formulas** (none yet). If you ever pin something like
  `postgresql@17`, the homebrew-core `@MAJOR.MINOR` filename + major-version alias
  convention is a fine choice — it's only wrong for the Ruby-isolation case above.

**Quick example — a purpose-named formula from `brew extract`:**
```bash
# brew extract writes a patch-versioned file; rename it to the purpose name
git mv Formula/openssl@3.5.4.rb Formula/openssl-ruby.rb

# Edit Formula/openssl-ruby.rb:
# Change: class OpensslAT354 < Formula
# To:     class OpensslRuby < Formula
# Update url/sha256, and use a string keg_only reason if it must stay unlinked.
```

---

## Understanding Tap Repository Locations

**Critical Context:** Before adding formulas, understand where Homebrew stores tap repositories and how the workflow works.

### Two Phases of Tap Development

#### Phase 1: Initial Setup (Creating the Tap)

When you **first create** a Homebrew tap, you typically:

1. **Create the repository on GitHub**: `dsaenztagarro/homebrew-tap`
2. **Develop initial content locally** in a convenient location:
   ```bash
   # Can be anywhere - your choice
   cd ~/Code  # or ~/Projects, ~/Development, etc.
   mkdir homebrew-tap
   cd homebrew-tap
   git init

   # Create initial files
   mkdir Formula
   touch README.md
   # Create initial formulas, documentation, etc.

   # Commit and push
   git add .
   git commit -m "Initial setup"
   git remote add origin git@github.com:dsaenztagarro/homebrew-tap.git
   git push -u origin master
   ```

3. **Push to GitHub**: Your tap is now public and ready to use

#### Phase 2: Ongoing Maintenance (After First Push)

After your tap is on GitHub, **you have two options** for ongoing work:

##### Option A: Work in Tap Location (RECOMMENDED - Standard Practice)

When you run `brew tap dsaenztagarro/tap`, Homebrew clones your repository to:
```
/opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap  (Apple Silicon)
# or
/usr/local/Homebrew/Library/Taps/dsaenztagarro/homebrew-tap  (Intel Mac)
```

**This IS a full-featured git repository!** You can:
- Make changes directly here
- Commit changes
- Push to GitHub
- Pull updates

```bash
# Navigate to tap location
cd $(brew --repository dsaenztagarro/tap)

# Check git status
git status

# See remote
git remote -v
# Shows: https://github.com/dsaenztagarro/homebrew-tap

# Make changes, commit, push
git add Formula/new-formula.rb
git commit -m "Add new formula"
git push
```

**Why this is recommended:**
- ✅ **`brew extract` puts formulas here automatically** - no copying needed
- ✅ **Single source of truth** - no syncing between locations
- ✅ **Changes are immediately testable** - `brew install` uses files from here
- ✅ **This is what most tap maintainers do**

##### Option B: Work in Personal Folder (Two-Location Workflow)

Keep working in your original development folder (e.g., `~/Code/homebrew-tap`):

```bash
# Work in your personal clone
cd ~/Code/homebrew-tap

# Make changes, commit, push
git add Formula/new-formula.rb
git commit -m "Add new formula"
git push

# Sync the tap location
brew update
```

**Challenges with this approach:**
- ⚠️ **Two locations to manage** - your folder + tap location
- ⚠️ **`brew extract` puts files in tap location** - you must copy them to your folder
- ⚠️ **Need to sync** - run `brew update` to see changes in tap location
- ⚠️ **More complex workflow** - easy to forget which location to use

### Recommended Workflow: Transition to Tap Location

**After your initial setup:**

1. **Push all commits from your development folder**:
   ```bash
   cd ~/Code/homebrew-tap  # or wherever you created it
   git push
   ```

2. **Tap the repository** (if not already tapped):
   ```bash
   brew tap dsaenztagarro/tap
   ```

3. **From now on, work in the tap location**:
   ```bash
   cd $(brew --repository dsaenztagarro/tap)
   pwd  # Shows: /opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap

   # This is now your working directory for all tap maintenance
   ```

4. **Optional: Remove your original clone** to avoid confusion:
   ```bash
   rm -rf ~/Code/homebrew-tap
   ```

### Quick Reference: Key Commands

```bash
# Find tap location
brew --repository dsaenztagarro/tap

# Navigate to tap location
cd $(brew --repository dsaenztagarro/tap)

# Check if you're in the tap location
pwd | grep "Library/Taps/dsaenztagarro"

# List tapped repositories
brew tap
```

---

## Prerequisites

Before adding a formula, ensure you have:

1. **Homebrew installed and up to date**:
   ```bash
   brew update
   ```

2. **The tap tapped locally**:
   ```bash
   brew tap dsaenztagarro/tap
   ```

   This creates a git repository at `/opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap`

3. **Navigate to the tap location** (recommended workflow):
   ```bash
   cd $(brew --repository dsaenztagarro/tap)
   ```

   **Note**: All instructions below assume you're working in the tap location.

4. **homebrew/core tapped with full git history** (required for `brew extract`):
   ```bash
   brew tap --force homebrew/core
   ```

   This downloads the full homebrew-core git repository (~500MB+) which is needed for `brew extract` to search version history.

---

## Method 1: Using `brew extract` (Recommended)

`brew extract` is the official Homebrew command for creating versioned copies of formulas. This is the recommended approach.

### Step 1: Find the Formula Version

First, identify the version you want to extract:

```bash
# Check the current version in homebrew-core
brew info <formula-name>

# Example:
brew info openssl@3
```

### Step 2: Find the Git Commit (Optional but Recommended)

For maximum reproducibility, you can find the specific commit in homebrew-core. **Note:** This step is entirely optional - you can skip directly to Step 3 and use `brew extract --version=X.Y.Z` without specifying a git revision. `brew extract` works out of the box without any additional setup.

#### Option A: Using GitHub Web Interface (Recommended)

Browse the formula history directly on GitHub - no local setup required:

```
https://github.com/Homebrew/homebrew-core/commits/master/Formula/<first-letter>/<formula-name>.rb
```

Examples:
- OpenSSL: https://github.com/Homebrew/homebrew-core/commits/master/Formula/o/openssl@3.rb
- Redis: https://github.com/Homebrew/homebrew-core/commits/master/Formula/r/redis.rb
- AWS CLI: https://github.com/Homebrew/homebrew-core/commits/master/Formula/a/awscli.rb

Click on commits to find the hash for your desired version.

#### Option B: Using Local homebrew-core Repository (Advanced Users Only)

**⚠️ Note:** Modern Homebrew (2021+) has homebrew/core built-in. You typically don't need to tap it manually, and doing so is only necessary for Homebrew contributors or advanced use cases.

If you really need local git access to homebrew-core:

```bash
# Force tap homebrew/core (only if you need local git access)
# This is NOT required for brew extract to work!
brew tap --force homebrew/core

# Navigate to the repository and find commits
cd $(brew --repository homebrew/core)

# Find commits for the formula
git log --oneline Formula/<first-letter>/<formula-name>.rb | head -20

# Example for openssl@3:
git log --oneline Formula/o/openssl@3.rb | head -20
```

Look for a commit that matches your desired version.

**Recommendation:** Use Option A (GitHub web interface) instead - it's simpler and doesn't require local repository setup.

### Step 3: Extract the Formula

**Important:** `brew extract` requires homebrew/core to be tapped with full git history:

```bash
# Required before first extraction (downloads ~500MB)
brew tap --force homebrew/core
```

Now extract the formula. **`brew extract` will save the formula directly to your tap location**:

```bash
# Make sure you're in the tap location (optional, but good practice)
cd $(brew --repository dsaenztagarro/tap)

# Extract specific version (recommended)
brew extract --version=<version> <formula-name> dsaenztagarro/tap

# Extract with specific commit (most reproducible - use commit from Step 2)
brew extract --version=<version> --git-revision=<commit> <formula-name> dsaenztagarro/tap

# Example: Extract openssl@3 version 3.5.4
brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap

# Output shows where the formula was saved:
==> Searching repository history
==> Writing formula for openssl at 3.5.4 from revision fa92749 to:
/opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap/Formula/openssl@3.5.4.rb
```

**Key Points:**
- ✅ The formula is saved **directly in the tap location**: `/opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap/Formula/`
- ✅ If you're working in the tap location (recommended), the file is **already in your git repository**
- ✅ The extracted file is named `openssl@3.5.4.rb` — you'll rename it to a purpose name in Step 4 (see [Versioning Strategy](#versioning-strategy))
- ⚠️ The `--git-revision` parameter is optional but recommended for maximum reproducibility

### Step 4: Name the formula and add a metadata header

`brew extract` writes a patch-versioned file (`openssl@3.5.4.rb`, `class OpensslAT354`).
Per the [Versioning Strategy](#versioning-strategy), rename it to a **purpose name** so it
won't match ruby-build's `^openssl@` auto-detection — this is exactly how the tap's
`openssl-ruby` formula was created:

```bash
cd $(brew --repository dsaenztagarro/tap)

# Confirm what brew extract wrote
ls -la Formula/          # -> Formula/openssl@3.5.4.rb

# Rename the extracted file to the purpose name
git mv Formula/openssl@3.5.4.rb Formula/openssl-ruby.rb

# Edit it (nano / code / vim)
code Formula/openssl-ruby.rb
```

Then, in the file:

1. **Rename the class** to match the file: `class OpensslAT354` → `class OpensslRuby`.
2. **Make it keg-only with a _string_ reason** (not `:versioned_formula`, which a name
   without an `@version` doesn't reliably honor) so it is never symlinked over the system
   `openssl@3`:
   ```ruby
   keg_only 'isolated OpenSSL for building Ruby; must not shadow openssl@3'
   ```
3. **Add a metadata header** above the `class`, recording where it came from and why:
   ```ruby
   # Formula for OpenSSL Ruby
   # Version: 3.5.4
   # Tracks the OpenSSL 3.5 LTS series (supported through 2030-04-08).
   # Originally scaffolded via:
   #   brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap
   # Source: homebrew/core commit 92c5c73
   # Reason: isolated, version-controlled OpenSSL for building Ruby
   #   (see docs/OPENSSL_RUBY_INCIDENT.md)
   # Tested on: macOS 14 (Sonoma) - arm64

   class OpensslRuby < Formula
     # ... rest of formula (generated by brew extract; adjust as needed)
   end
   ```

> **Pinning a general-purpose tool instead?** If you're pinning something like PostgreSQL
> rather than isolating it, keep the homebrew-core `@MAJOR.MINOR` name
> (`git mv Formula/postgresql@17.3.rb Formula/postgresql@17.rb`, `class PostgresqlAT17`) and
> skip the keg-only step. See [Versioning Strategy](#versioning-strategy).

---

## Method 2: Manual Formula Creation

For formulas not in homebrew-core, or for custom formulas.

### Step 1: Create Formula File

```bash
# Navigate to tap location
cd $(brew --repository dsaenztagarro/tap)/Formula

# Create new formula file
touch <formula-name>.rb
```

### Step 2: Write the Formula

Use the standard Homebrew formula template:

```ruby
# Formula for <package-name>
# Version: X.Y.Z
# Created date: YYYY-MM-DD
# Source: [upstream URL or description]
# Reason: [Why this formula is needed]
# Tested on: [OS and architecture]

class PackageName < Formula
  desc "Short description of the package"
  homepage "https://package-homepage.com"
  url "https://download-url.com/package-x.y.z.tar.gz"
  sha256 "sha256-checksum-here"
  license "LICENSE-TYPE"

  # Build dependencies (only needed during build)
  depends_on "cmake" => :build
  depends_on "pkg-config" => :build

  # Runtime dependencies
  depends_on "other-package"

  def install
    # Installation steps
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    # Test to verify installation
    system "#{bin}/package", "--version"
  end
end
```

### Step 3: Calculate SHA256 Checksum

```bash
# Download the source file
curl -L -O <download-url>

# Calculate SHA256
shasum -a 256 <filename>
```

---

## Formula Validation

Before committing, validate the formula:

### 1. Audit the Formula

```bash
brew audit --strict --online <formula-name>

# Example:
brew audit --strict --online dsaenztagarro/tap/openssl-ruby
```

### 2. Check Formula Style

```bash
brew style <formula-path>

# Example:
brew style Formula/openssl-ruby.rb
```

### 3. Run Formula Tests (if available)

```bash
brew test <formula-name>

# Example:
brew test dsaenztagarro/tap/openssl-ruby
```

---

## Testing the Formula

### 1. Install from Source

```bash
# Install and build from source
brew install --build-from-source dsaenztagarro/tap/<formula-name>

# Example:
brew install --build-from-source dsaenztagarro/tap/openssl-ruby
```

### 2. Verify Installation

```bash
# Check installation
brew info <formula-name>

# Verify the binary works
<binary-name> --version

# Example: openssl-ruby is keg-only, so it isn't on PATH — call it via its prefix
"$(brew --prefix openssl-ruby)/bin/openssl" version
```

### 3. Test with Dependent Projects

If the formula is a dependency for your projects, test integration:

```bash
cd /path/to/your/project
bundle install  # or equivalent for your project
# Run project tests
```

### 4. Check for Conflicts

```bash
brew doctor
```

---

## Committing the Formula

Changes ship through a pull request — **not** a direct push to `master` — following the
tap's [shipping flow](docs/VERSIONING_STRATEGY.md#shipping-changes): issue → branch → PR
(`Closes #n`) → squash-merge. You can run all of this from the tap location (it's a full git
repo with the `origin` remote) or from a personal clone.

### 1. Review the change

```bash
cd $(brew --repository dsaenztagarro/tap)   # or your personal clone

pwd            # -> /opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap
git status     # new/modified files under Formula/
git diff Formula/openssl-ruby.rb
```

### 2. Open an issue

Record the motivation, the change, and the impact:

```bash
gh issue create \
  --title "Add openssl-ruby formula (OpenSSL 3.5 LTS for Ruby)" \
  --label enhancement \
  --body "Isolated, version-controlled OpenSSL for building Ruby. Extracted from
openssl@3 3.5.4 and renamed to a purpose name so it doesn't match ruby-build's
^openssl@ auto-detection. See docs/OPENSSL_RUBY_INCIDENT.md."
# -> https://github.com/dsaenztagarro/homebrew-tap/issues/N
```

### 3. Branch, commit, push

```bash
git checkout -b add-openssl-ruby

git add Formula/openssl-ruby.rb
git commit -m "Add openssl-ruby formula (OpenSSL 3.5.4)

- Isolated OpenSSL for building Ruby; keg-only (string reason)
- Extracted: brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap
- Source: homebrew/core commit 92c5c73
- Tested on: macOS 14 (Sonoma) - arm64

Closes #N"

git push -u origin add-openssl-ruby
```

### 4. Open the PR, let CI run, squash-merge

```bash
gh pr create --base master --fill --label enhancement

# CI (Formula Tests) audits, builds from source, and runs `brew test` on macos-14.
gh pr checks --watch

# Once checks are green:
gh pr merge --squash --delete-branch
```

The formula is now on `master` and immediately available to anyone with the tap
(`brew update && brew install dsaenztagarro/tap/openssl-ruby`). `brew` serves it from HEAD —
there are no tags or release steps to run.

### Summary: extract → ship

```bash
cd $(brew --repository dsaenztagarro/tap)

brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap  # writes openssl@3.5.4.rb
git mv Formula/openssl@3.5.4.rb Formula/openssl-ruby.rb   # rename to purpose name
code Formula/openssl-ruby.rb                              # class + keg_only + metadata

gh issue create --title "Add openssl-ruby formula" --label enhancement --body "..."
git checkout -b add-openssl-ruby
git add Formula/openssl-ruby.rb
git commit -m "Add openssl-ruby formula (OpenSSL 3.5.4)

Closes #N"
git push -u origin add-openssl-ruby
gh pr create --base master --fill --label enhancement
gh pr merge --squash --delete-branch                     # after CI is green
```

> Working from a personal clone instead of the tap location? The flow is identical —
> `brew extract` writes into the tap location, so copy the file into your clone
> (`cp "$(brew --repository dsaenztagarro/tap)"/Formula/openssl@3.5.4.rb Formula/`) before
> the `git mv`, then branch and open the PR from there.

---

## Decision Framework

### When to Add a Formula

✅ **Should Add:**
- Critical development dependencies (databases, SSL libraries, language runtimes)
- Tools used frequently across multiple projects
- Packages requiring specific version pinning
- Security-sensitive packages requiring controlled updates
- Tools with breaking changes between versions
- Build-time dependencies for personal projects

❌ **Should NOT Add:**
- Tools rarely used
- Packages with stable APIs that rarely break
- Packages better managed by other package managers (npm, gem, pip, cargo)
- Experimental or bleeding-edge tools (unless specifically needed)
- Packages that update daily/weekly (maintenance burden)

### Evaluation Checklist

Before adding a formula, ask:

- [ ] Do I use this tool regularly?
- [ ] Is version pinning important for this tool?
- [ ] Will this formula help maintain consistent environments?
- [ ] Can I maintain this formula (security updates, version bumps)?
- [ ] Is this the right package manager for this tool?

---

## Examples

These extract *general-purpose* tools, so they take the homebrew-core `@MAJOR.MINOR` name
(not a purpose name) and are **not** keg-only. Add a metadata header to each, then ship it
via the PR flow in [Committing the Formula](#committing-the-formula).

### Example 1: Pinning Redis 7.2

```bash
brew info redis                                        # find the version
brew extract --version=7.2.3 redis dsaenztagarro/tap   # writes redis@7.2.3.rb

cd $(brew --repository dsaenztagarro/tap)
git mv Formula/redis@7.2.3.rb Formula/redis@7.2.rb     # minor-version name
# In the file: class Redis... -> class RedisAT72, then add a metadata header.
```

### Example 2: Pinning AWS CLI 2.13

```bash
# Optionally pin the exact homebrew-core commit for reproducibility — find it at
# https://github.com/Homebrew/homebrew-core/commits/master/Formula/a/awscli.rb
brew extract --version=2.13.25 --git-revision=<commit> awscli dsaenztagarro/tap

cd $(brew --repository dsaenztagarro/tap)
git mv Formula/awscli@2.13.25.rb Formula/awscli@2.13.rb   # class AwscliAT213
# Add a metadata header, then ship via the PR flow.
```

---

## Troubleshooting

### Issue: "Tapping homebrew/core is no longer typically necessary"

**Cause:** Modern Homebrew (2021+) has homebrew/core built-in and doesn't require manual tapping.

**Solution:**

This is **not an error** - it's Homebrew telling you that you don't need to tap homebrew/core. You have three options:

**Option 1 (Recommended):** Use GitHub web interface to find commits
- Browse https://github.com/Homebrew/homebrew-core/commits/master/Formula/...
- No local setup needed

**Option 2 (Simplest):** Skip finding git commits entirely
```bash
# Just use brew extract with version - it works without git-revision
brew extract --version=X.Y.Z <formula-name> dsaenztagarro/tap
```

**Option 3 (Advanced):** Force tap if you really need local git access
```bash
# Only use this if you need local git history access
brew tap --force homebrew/core

# Now you can access the repository
cd $(brew --repository homebrew/core)
```

**Recommendation:** Use Option 1 or 2. Option 3 is only needed for Homebrew contributors or very specific use cases.

### Issue: "No such file or directory" when accessing homebrew/core

**Cause:** You're trying to access the local repository without force-tapping it.

**Solution:**

Don't access the local repository - use the GitHub web interface instead:
- https://github.com/Homebrew/homebrew-core/commits/master/Formula/...

Or simply use `brew extract --version=X.Y.Z` without the `--git-revision` parameter.

### Issue: "Formula not found" during extraction

**Cause:** The formula or version doesn't exist in homebrew-core history.

**Solution:**
```bash
# Check if formula exists
brew search <formula-name>

# Check current version available
brew info <formula-name>

# Browse formula history on GitHub to verify version exists
# https://github.com/Homebrew/homebrew-core/commits/master/Formula/<letter>/<formula-name>.rb
```

If the formula or version truly doesn't exist in homebrew-core history, `brew extract` will fail. Verify the formula name and version are correct.

### Issue: "Permission denied" during extraction

**Cause:** No write access to tap repository.

**Solution:**
```bash
# Check repository permissions
cd $(brew --repository dsaenztagarro/tap)
ls -la
git remote -v
```

### Issue: Formula installs but wrong version

**Cause:** Class name doesn't match filename.

**Solution:**
```bash
# Ensure the class name matches the filename:
# File: openssl-ruby.rb   -> class OpensslRuby
# File: redis@7.2.rb      -> class RedisAT72
```

### Issue: Audit failures

**Cause:** Formula doesn't meet Homebrew standards.

**Solution:**
```bash
# Run audit to see specific issues
brew audit --strict --online <formula-name>

# Fix reported issues in formula file
# Common issues: missing license, incorrect URLs, style violations
```

---

## Best Practices

1. **Always use `brew extract` with `--git-revision`** for maximum reproducibility
2. **Add comprehensive metadata headers** to document extraction details
3. **Test formulas thoroughly** before committing
4. **Use semantic commit messages** that explain why the formula was added
5. **Document the reason** for choosing a specific version
6. **Keep formulas updated** with security patches
7. **Remove unused formulas** to reduce maintenance burden
8. **Maintain at least 2 versions** during transition periods

---

## Resources

- [Homebrew Documentation](https://docs.brew.sh/)
- [brew extract Manual](https://docs.brew.sh/Manpage#extract-options-formula-tap)
- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [How to Create a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Homebrew Formula Documentation](https://rubydoc.brew.sh/Formula)

---

**Last Updated:** 2026-07-04
**Maintained by:** David Saenz Tagarro

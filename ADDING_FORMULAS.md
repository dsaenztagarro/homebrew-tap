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

**Important:** Before adding formulas, understand Homebrew's versioning conventions.

This tap follows the official Homebrew naming conventions for versioned formulas:

- **Formula files** use `@X.Y` format (e.g., `openssl@3.5.rb`)
- **Class names** match the file (e.g., `class OpensslAT35 < Formula`)
- **Aliases** provide convenience shortcuts (e.g., `openssl@3` → `openssl@3.5.rb`)

**Why this matters:**
- `brew extract` creates files like `openssl@3.5.4.rb` (includes patch version)
- You should rename these to follow conventions: `openssl@3.5.rb`
- This keeps your tap consistent with homebrew-core practices

For detailed information about versioning, naming conventions, and update strategies, see:
**[docs/VERSIONING_STRATEGY.md](docs/VERSIONING_STRATEGY.md)**

**Quick example:**
```bash
# After extracting with brew extract
git mv Formula/openssl@3.5.4.rb Formula/openssl@3.5.rb

# Edit Formula/openssl@3.5.rb:
# Change: class OpensslAT354 < Formula
# To:     class OpensslAT35 < Formula

# Create convenience aliases
mkdir -p Aliases
cd Aliases
ln -s ../Formula/openssl@3.5.rb openssl@3
ln -s ../Formula/openssl@3.5.rb openssl@3.5.4  # backward compatibility
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
- ✅ You can **immediately test** the formula: `brew install dsaenztagarro/tap/openssl@3.5.4`
- ⚠️ The `--git-revision` parameter is optional but recommended for maximum reproducibility

### Step 4: Add Metadata Header

The extracted formula is now in your tap's git repository. Add documentation to track extraction details:

```bash
# Navigate to tap location (if not already there)
cd $(brew --repository dsaenztagarro/tap)

# Verify the formula was created
ls -la Formula/
# You should see: openssl@3.5.4.rb (or whatever you extracted)

# Edit the formula to add metadata header
# Use your preferred editor
nano Formula/openssl@3.5.4.rb
# or
code Formula/openssl@3.5.4.rb
# or
vim Formula/openssl@3.5.4.rb
```

**Add this metadata header** at the top of the formula file (before the `class` definition):

```ruby
# Formula for openssl@3
# Version: 3.5.4
# Extracted date: 2025-11-14
# Extraction command: brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap
# Source: homebrew/core commit 92c5c73
# Homebrew core URL: https://github.com/Homebrew/homebrew-core/blob/92c5c73/Formula/o/openssl@3.rb
# Reason: Stable SSL library for development projects
# Tested on: macOS 14 (Sonoma) - arm64

class OpensslAT354 < Formula
  # ... rest of formula (automatically generated by brew extract)
end
```

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
brew audit --strict --online dsaenztagarro/tap/openssl@3
```

### 2. Check Formula Style

```bash
brew style <formula-path>

# Example:
brew style Formula/openssl@3.rb
```

### 3. Run Formula Tests (if available)

```bash
brew test <formula-name>

# Example:
brew test dsaenztagarro/tap/openssl@3
```

---

## Testing the Formula

### 1. Install from Source

```bash
# Install and build from source
brew install --build-from-source dsaenztagarro/tap/<formula-name>

# Example:
brew install --build-from-source dsaenztagarro/tap/openssl@3
```

### 2. Verify Installation

```bash
# Check installation
brew info <formula-name>

# Verify the binary works
<binary-name> --version

# Example:
openssl version
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

**Critical:** You should commit from the tap location where the formula was created.

### 1. Review Changes in Tap Location

```bash
# Navigate to tap location (if not already there)
cd $(brew --repository dsaenztagarro/tap)

# Verify you're in the right place
pwd
# Should show: /opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap

# Check what changed
git status
# Should show: modified or new files in Formula/

# Review the changes
git diff Formula/openssl@3.5.4.rb
```

### 2. Add and Commit

```bash
# Still in tap location: $(brew --repository dsaenztagarro/tap)

# Add the formula (or use git add . to add all changes)
git add Formula/<formula-name>.rb

# Commit with descriptive message
git commit -m "Add <formula-name> formula (version X.Y.Z)

- Short description of the package
- Version: X.Y.Z
- SHA256: <checksum>
- Extracted using: brew extract --version=X.Y.Z <formula> dsaenztagarro/tap
- Source: homebrew/core commit <commit-hash>
- Reason: [why this formula is added]
- Tested on: [OS and architecture]"

# Example for openssl@3 version 3.5.4:
git commit -m "Add openssl@3 formula (version 3.5.4)

- Cryptography and SSL/TLS Toolkit
- Version: 3.5.4
- SHA256: 9a61314bab711124e094b8c4dcc33653bdd66f64ab6e3c0b5e73ab50cac27c3a
- Extracted using: brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap
- Source: homebrew/core commit 92c5c73
- Reason: Stable SSL library for development projects
- Tested on: macOS 14 (Sonoma) - arm64"
```

### 3. Push to GitHub

```bash
# Still in tap location: $(brew --repository dsaenztagarro/tap)

# Push to GitHub
git push origin master
# or: git push origin main (depending on your default branch name)

# Verify push succeeded
git log --oneline -1
```

### 4. Verify Formula is Available

After pushing, the formula is immediately available to anyone who has your tap:

```bash
# Update tap to get latest changes
brew update

# Install your newly added formula
brew install dsaenztagarro/tap/<formula-name>

# Example:
brew install dsaenztagarro/tap/openssl@3.5.4
```

### Summary: Complete Workflow from Extraction to Push

```bash
# 1. Navigate to tap location (do this once)
cd $(brew --repository dsaenztagarro/tap)

# 2. Extract formula (saves directly here)
brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap

# 3. Edit formula to add metadata header
code Formula/openssl@3.5.4.rb

# 4. Review changes
git status
git diff

# 5. Commit
git add Formula/openssl@3.5.4.rb
git commit -m "Add openssl@3 formula (version 3.5.4)"

# 6. Push
git push

# Done! Formula is now public and usable.
```

### Alternative: Two-Location Workflow (Not Recommended)

If you prefer to keep working in a personal development folder instead of the tap location:

```bash
# 1. Extract formula (still goes to tap location)
brew extract --version=3.5.4 openssl@3 dsaenztagarro/tap

# 2. Copy formula from tap location to personal folder
cp /opt/homebrew/Library/Taps/dsaenztagarro/homebrew-tap/Formula/openssl@3.5.4.rb \
   ~/Code/homebrew-tap/Formula/

# 3. Edit in personal folder
cd ~/Code/homebrew-tap
code Formula/openssl@3.5.4.rb

# 4. Commit and push from personal folder
git add Formula/openssl@3.5.4.rb
git commit -m "Add openssl@3 formula (version 3.5.4)"
git push

# 5. Update tap location to sync changes
brew update
```

**Why this is not recommended:**
- ⚠️ Extra manual step (copying files)
- ⚠️ Easy to forget which location is current
- ⚠️ Need to remember to run `brew update` to sync
- ⚠️ More error-prone workflow

**Use this only if you have a specific reason to keep a separate development clone.**

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

### Example 1: Extracting Redis

```bash
# Find the version you want
brew info redis

# Extract specific version
brew extract --version=7.2.3 redis dsaenztagarro/tap

# Navigate to formula
cd $(brew --repository dsaenztagarro/tap)/Formula

# Add metadata header to redis@7.2.3.rb
# Then commit
git add redis@7.2.3.rb
git commit -m "Add redis formula (version 7.2.3)

- Redis in-memory data structure store
- Version: 7.2.3
- Source: homebrew/core
- Reason: Cache and job queue for development projects
- Tested on: macOS 14 (Sonoma) - arm64"
```

### Example 2: Adding AWS CLI

```bash
# Option A: Simple extraction (recommended - no git commit needed)
brew extract --version=2.13.25 awscli dsaenztagarro/tap

# Option B: With git commit for maximum reproducibility
# First, find the commit using GitHub:
# Visit: https://github.com/Homebrew/homebrew-core/commits/master/Formula/a/awscli.rb
# Find the commit hash for version 2.13.25 (e.g., xyz9876)

# Extract with specific commit
brew extract --version=2.13.25 --git-revision=xyz9876 awscli dsaenztagarro/tap

# Add metadata and commit
cd $(brew --repository dsaenztagarro/tap)
# Edit Formula/awscli@2.13.25.rb to add metadata header
git add Formula/awscli@2.13.25.rb
git commit -m "Add awscli formula (version 2.13.25)

- Official Amazon AWS command-line interface
- Version: 2.13.25
- SHA256: [checksum]
- Source: homebrew/core commit xyz9876
- Reason: AWS infrastructure management tool
- Tested on: macOS 14 (Sonoma) - arm64"
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
# Ensure filename matches class name
# File: openssl@3.2.0.rb
# Class: class OpensslAT320 < Formula
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

**Last Updated:** 2025-11-14
**Maintained by:** David Saenz Tagarro

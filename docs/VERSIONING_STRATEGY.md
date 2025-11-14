# Versioning Strategy

This document explains how formulas are versioned and aliased in this tap, following Homebrew's standard conventions.

## Formula Naming Convention

This tap follows Homebrew's standard versioning convention used in homebrew-core:

- **Formula files**: Named with MINOR version (`@X.Y`)
- **Patches**: Tracked within the formula file
- **Aliases**: Provide convenient install shortcuts

### Pattern Comparison

#### Homebrew Core Example (OpenSSL):
```
Formula/o/openssl@3.rb     → Contains OpenSSL 3.6.0 (class OpensslAT3)
Formula/o/openssl@3.5.rb   → Contains OpenSSL 3.5.4 (class OpensslAT35)
Formula/o/openssl@3.0.rb   → Contains OpenSSL 3.0.x (class OpensslAT30)

Aliases/openssl            → Points to openssl@3.rb
Aliases/openssl@3.6        → Points to openssl@3.rb
```

#### This Tap Example (OpenSSL):
```
Formula/openssl@3.5.rb     → Contains OpenSSL 3.5.4 (class OpensslAT35)

Aliases/openssl@3          → Points to openssl@3.5.rb
Aliases/openssl@3.5.4      → Points to openssl@3.5.rb (backward compatibility)
```

### Why Use Minor Version in Filename?

**Standard**: `openssl@3.5.rb` (minor version)
- ✅ Follows Homebrew conventions
- ✅ Patch updates don't require file renames
- ✅ Clear intent: "track 3.5.x series"
- ✅ Easy to maintain

**Non-standard**: `openssl@3.5.4.rb` (patch version)
- ❌ Not conventional
- ❌ Requires file rename for patch updates
- ❌ Clutters formula directory
- ❌ Confusing for users

## Installing Formulas

### Recommended Installation

Use the **minor version** for stability:

```bash
# Install using minor version (recommended)
brew install dsaenztagarro/tap/openssl@3.5

# Shows: Installing openssl@3.5 which contains version 3.5.4
```

### Convenience Aliases

Use **major version** for convenience:

```bash
# Install using major version (gets current preferred 3.x)
brew install dsaenztagarro/tap/openssl@3

# This resolves to whatever openssl@3 alias points to (currently @3.5)
```

### Specific Patch (Backward Compatibility)

```bash
# Install using specific patch version (via alias)
brew install dsaenztagarro/tap/openssl@3.5.4

# This resolves to openssl@3.5.rb via alias
```

### What Gets Installed?

All three commands above install **the same formula**:
- Formula file: `Formula/openssl@3.5.rb`
- Version contained: OpenSSL 3.5.4
- Class name: `OpensslAT35`

The `@3` and `@3.5.4` are just **aliases** (symlinks) pointing to `@3.5`.

## Updating Strategies

### Patch Updates (3.5.4 → 3.5.5)

When a new patch is released in the same minor series:

```bash
# Navigate to tap location
cd $(brew --repository dsaenztagarro/tap)

# Edit the formula file in-place
vim Formula/openssl@3.5.rb

# Update the version URL and SHA256
# Change: url "https://.../openssl-3.5.4.tar.gz"
# To:     url "https://.../openssl-3.5.5.tar.gz"

# Update SHA256 checksum
# Change: sha256 "old-hash"
# To:     sha256 "new-hash"

# Test the update
brew uninstall openssl@3.5
brew install dsaenztagarro/tap/openssl@3.5

# Commit
git add Formula/openssl@3.5.rb
git commit -m "openssl@3.5: update to 3.5.5"
git push
```

**No file rename needed!** Just update the contents.

### Minor Updates (3.5.x → 3.6.x)

When you want to track a new minor series:

```bash
# Navigate to tap location
cd $(brew --repository dsaenztagarro/tap)

# Extract the new minor version
brew extract --version=3.6.0 openssl@3 dsaenztagarro/tap

# Rename from brew extract output
mv Formula/openssl@3.6.0.rb Formula/openssl@3.6.rb

# Edit the formula to update class name
# Change: class OpensslAT360 < Formula
# To:     class OpensslAT36 < Formula

# Add metadata header with extraction info

# Test
brew install dsaenztagarro/tap/openssl@3.6

# Update the major version alias to point to new minor
cd Aliases
rm openssl@3
ln -s ../Formula/openssl@3.6.rb openssl@3

# Commit
git add Formula/openssl@3.6.rb Aliases/openssl@3
git commit -m "openssl@3.6: add version 3.6.0

- Extract from homebrew-core
- Update openssl@3 alias to point to 3.6
- Previous 3.5 series remains available"
git push
```

### Major Updates (3.x → 4.x)

If OpenSSL 4.0 is released:

```bash
# Extract the new major version
brew extract --version=4.0.0 openssl@4 dsaenztagarro/tap

# Rename to minor version
mv Formula/openssl@4.0.0.rb Formula/openssl@4.0.rb

# Update class name: OpensslAT400 → OpensslAT40

# Create new major alias
cd Aliases
ln -s ../Formula/openssl@4.0.rb openssl@4

# Commit
git add Formula/openssl@4.0.rb Aliases/openssl@4
git commit -m "openssl@4.0: add version 4.0.0"
git push
```

**Keep the old major series available:**
- `openssl@3` → points to `openssl@3.5.rb` (or whatever 3.x you prefer)
- `openssl@4` → points to `openssl@4.0.rb`

## Alias Management

### Creating Aliases

Aliases are **symlinks** in the `Aliases/` directory:

```bash
cd $(brew --repository dsaenztagarro/tap)
mkdir -p Aliases
cd Aliases

# Create major version alias
ln -s ../Formula/openssl@3.5.rb openssl@3

# Create patch version alias (optional, for backward compatibility)
ln -s ../Formula/openssl@3.5.rb openssl@3.5.4

# Verify
ls -la
# Should show:
# openssl@3 -> ../Formula/openssl@3.5.rb
# openssl@3.5.4 -> ../Formula/openssl@3.5.rb

# Add to git
git add openssl@3 openssl@3.5.4
```

### Updating Aliases

When you want to change what a major version points to:

```bash
cd $(brew --repository dsaenztagarro/tap)/Aliases

# Remove old symlink
rm openssl@3

# Create new symlink
ln -s ../Formula/openssl@3.6.rb openssl@3

# Commit
git add openssl@3
git commit -m "Update openssl@3 alias to point to 3.6"
git push
```

### Alias Strategy

| Alias Name | Points To | Purpose |
|------------|-----------|---------|
| `openssl@3` | `Formula/openssl@3.5.rb` | Convenient major version install |
| `openssl@3.5.4` | `Formula/openssl@3.5.rb` | Backward compatibility with old naming |

## Migration Example: Renaming Existing Formula

If you have `openssl@3.5.4.rb` and want to follow conventions:

```bash
cd $(brew --repository dsaenztagarro/tap)

# 1. Rename the file
git mv Formula/openssl@3.5.4.rb Formula/openssl@3.5.rb

# 2. Update class name in the file
# Change: class OpensslAT354 < Formula
# To:     class OpensslAT35 < Formula

# 3. Create aliases for backward compatibility
mkdir -p Aliases
cd Aliases
ln -s ../Formula/openssl@3.5.rb openssl@3
ln -s ../Formula/openssl@3.5.rb openssl@3.5.4

# 4. Commit
git add Formula/openssl@3.5.rb Aliases/
git commit -m "Restructure openssl formula to follow conventions

- Rename openssl@3.5.4.rb to openssl@3.5.rb
- Update class name from OpensslAT354 to OpensslAT35
- Add openssl@3 alias for major version convenience
- Add openssl@3.5.4 alias for backward compatibility"

# 5. Push
git push
```

After migration:
```bash
# All these work and install the same formula:
brew install dsaenztagarro/tap/openssl@3      ✅ (via alias)
brew install dsaenztagarro/tap/openssl@3.5    ✅ (direct - recommended)
brew install dsaenztagarro/tap/openssl@3.5.4  ✅ (via alias - backward compat)
```

## Why This Convention?

### 1. Standard Practice
Matches homebrew-core conventions that users are familiar with.

### 2. Clear Intent
`openssl@3.5` clearly communicates "OpenSSL 3.5.x series" rather than a specific patch.

### 3. Easy Updates
Patch updates (3.5.4 → 3.5.5) only require editing the formula file, not renaming files and updating references.

### 4. Flexibility
Aliases provide shortcuts while maintaining clarity about which series is being tracked.

### 5. Maintainability
Fewer files in `Formula/` directory when tracking patches within minor versions.

## Real-World Examples from Homebrew Core

### PostgreSQL
```
postgresql@17.rb  → PostgreSQL 17.x
postgresql@16.rb  → PostgreSQL 16.x
postgresql@15.rb  → PostgreSQL 15.x
```
Uses **major version** in filename, tracks patches inside.

### PHP
```
php@8.3.rb  → PHP 8.3.x
php@8.2.rb  → PHP 8.2.x
php@8.1.rb  → PHP 8.1.x
```
Uses **minor version** in filename, tracks patches inside.

### Node
```
node@22.rb  → Node.js 22.x
node@20.rb  → Node.js 20.x
node@18.rb  → Node.js 18.x
```
Uses **major version** in filename, tracks minor and patches inside.

### OpenSSL (Most Relevant)
```
openssl@3.5.rb  → OpenSSL 3.5.4 (and future 3.5.x patches)
openssl@3.0.rb  → OpenSSL 3.0.x
openssl@3.rb    → OpenSSL 3.6.0 (latest 3.x)
```
Uses **minor version** in filename for older series, major for latest.

## Backward Compatibility

### Old Installations

If users previously installed using:
```bash
brew install dsaenztagarro/tap/openssl@3.5.4
```

After restructuring with alias, this **continues to work**:
- The `openssl@3.5.4` alias points to `openssl@3.5.rb`
- Users don't need to change their scripts or workflows
- Migration is seamless

### Deprecating Old Names

If you want to eventually remove the `@3.5.4` alias:

1. **Keep it for at least 6 months** after restructuring
2. **Add deprecation notice** in commit messages and release notes
3. **Remove alias** in a later release with clear communication

## Summary

- ✅ **Use minor version** in formula filenames: `@X.Y`
- ✅ **Track patches** within the formula file
- ✅ **Create aliases** for major versions and backward compatibility
- ✅ **Update patches in-place** without file renames
- ✅ **Follow Homebrew conventions** for familiarity

---

**Last Updated**: 2025-11-14  
**Maintained by**: David Saenz Tagarro

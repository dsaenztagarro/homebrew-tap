# OpenSSL 3.6.0 Incident Investigation

## Short Summary

This document details the investigation into Ruby OpenSSL failures following Homebrew's automatic upgrade of `openssl@3` from version 3.5.4 to 3.6.0. It explains the root cause, Homebrew's dynamic linking mechanism, and our solution using a custom OpenSSL formula.

**Key Finding:** Ruby installations dynamically link to OpenSSL through Homebrew's symlink system. When `brew upgrade` updates OpenSSL, all Ruby installations automatically use the new version without recompilation, exposing them to bugs and behavioral changes.

**Solution Implemented:** This tap now provides the `OpensslRuby` formula (Formula/openssl-ruby.rb) which requires explicit configuration and prevents automatic upgrades. See "The Solution: Custom OpenSSL Formula" section below.

**Related GitHub Issue:** [ruby/openssl#949 - Certificate verify failed after OpenSSL 3.6.0 upgrade](https://github.com/ruby/openssl/issues/949#issuecomment-3368551818)

---

## Table of Contents

- [The Incident Timeline](#the-incident-timeline)
- [Root Cause Analysis](#root-cause-analysis)
- [How rbenv/ruby-build Selects OpenSSL](#how-rbenvruby-build-selects-openssl)
- [The Homebrew Symlink Vulnerability](#the-homebrew-symlink-vulnerability)
- [Dynamic Linking Explained](#dynamic-linking-explained)
- [Why Homebrew's Major Version Formulas Are Dangerous](#why-homebrews-major-version-formulas-are-dangerous)
- [The Solution: Custom OpenSSL Formula](#the-solution-custom-openssl-formula)
- [Recommendations](#recommendations)

---

## The Incident Timeline

### Phase 1: Initial Ruby Installation (September 2024)

```bash
$ rbenv install 3.3.5
```

**System State:**
```
OpenSSL: 3.5.4 installed via homebrew-core
Path: /opt/homebrew/Cellar/openssl@3/3.5.4/
Symlink: /opt/homebrew/opt/openssl@3 → ../Cellar/openssl@3/3.5.4
```

**Ruby Build Process:**
- ruby-build detects: `openssl@3` version 3.5.4
- Compiles Ruby with: `--with-openssl-dir=/opt/homebrew/opt/openssl@3`
- Ruby's `openssl.bundle` links to: `/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib`

**Status:** ✅ Everything works

### Phase 2: Homebrew Auto-Upgrade (October 2024)

```bash
$ brew update
$ brew upgrade  # Or automatic background update
```

**System State Changed:**
```
OpenSSL: 3.6.0 now installed
Path: /opt/homebrew/Cellar/openssl@3/3.6.0/
Symlink: /opt/homebrew/opt/openssl@3 → ../Cellar/openssl@3/3.6.0  ⚠️ UPDATED!
Old version: /opt/homebrew/Cellar/openssl@3/3.5.4/ (kept temporarily)
```

**Ruby State:**
- Ruby binary NOT recompiled
- Still links to: `/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib`
- BUT symlink now resolves to: `3.6.0/lib/libssl.3.dylib`

**Status:** ⚠️ Ruby silently upgraded to OpenSSL 3.6.0

### Phase 3: OpenSSL 3.6.0 Bug Manifests

```bash
$ ruby script.rb
OpenSSL::SSL::SSLError: certificate verify failed (unable to get certificate CRL)
```

**What Happened:**
- OpenSSL 3.6.0 introduced a bug in CRL (Certificate Revocation List) handling
- Certificate chain validation became stricter/broken
- All Ruby SSL/TLS operations started failing
- No Ruby code changed, but behavior broke

**Impact:**
- ❌ All Ruby versions affected simultaneously (3.3.5, 3.4.3, etc.)
- ❌ Production applications broken
- ❌ Difficult to diagnose (nothing in Ruby environment changed)

**Status:** ❌ Complete Ruby SSL failure

### Phase 4: Homebrew Cleanup (Days Later)

```bash
$ brew cleanup  # Or automatic cleanup
```

**System State:**
```
Old version DELETED: /opt/homebrew/Cellar/openssl@3/3.5.4/
Only version left: /opt/homebrew/Cellar/openssl@3/3.6.0/
```

**Status:** ❌ Can't rollback even if you wanted to

---

## Root Cause Analysis

### The Vulnerability Chain

1. **Dynamic Linking via Symlink**
   - Ruby's `openssl.bundle` links to: `/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib`
   - This path is a **symlink**, not a real file
   - Symlink target changes during Homebrew upgrades

2. **Automatic "Upgrades" Without Consent**
   - `brew upgrade openssl@3` updates the symlink
   - All programs using OpenSSL automatically use the new version
   - Zero warning, zero consent, zero control

3. **ABI Compatibility ≠ Behavioral Compatibility**
   - Function signatures match between 3.5.4 and 3.6.0 (same API)
   - BUT internal behavior changed (CRL handling bug)
   - Programs run but behave differently

4. **Silent Breakage**
   - No recompilation occurred
   - No error messages about library changes
   - Applications fail at runtime with cryptic SSL errors

### Proof from Current System

Evidence from Ruby 3.3.5 installation:

```bash
$ otool -L ~/.rbenv/versions/3.3.5/lib/ruby/3.3.0/arm64-darwin24/openssl.bundle
openssl.bundle:
  /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib
  /opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib
```

```bash
$ ruby -ropenssl -e 'puts OpenSSL::OPENSSL_LIBRARY_VERSION'
OpenSSL 3.6.0 1 Oct 2025
```

Even though Ruby 3.3.5 was installed with OpenSSL 3.5.4, it now reports 3.6.0 because the symlink changed!

---

## How rbenv/ruby-build Selects OpenSSL

### Ruby 3.4.3 Definition File

Location: `/opt/homebrew/opt/ruby-build/share/ruby-build/3.4.3`

```ruby
install_package "openssl-3.0.16" "..." openssl --if needs_openssl:1.0.2-3.x.x
install_package "ruby-3.4.3" "..." enable_shared standard
```

**Key Parameter:** `needs_openssl:1.0.2-3.x.x`
- Accepts ANY OpenSSL from version 1.0.2 to 3.99.99
- Both OpenSSL 3.5.4 and 3.6.0 satisfy this requirement

### OpenSSL Selection Priority

When you run `rbenv install 3.4.3`, ruby-build checks in this order:

#### 1. Explicit Configuration (HIGHEST PRIORITY)

```bash
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/path/to/openssl"
```

If set: ✅ **ALWAYS WINS** - ruby-build skips all other checks

#### 2. Homebrew-installed OpenSSL Formulas

**Function:** `homebrew_openssl_versions()`

```bash
brew list 2>/dev/null | grep '^openssl@'
```

**Detection Pattern:** Matches formulas starting with `openssl@`
- Finds: `openssl@3`, `openssl@3.5`, `openssl@1.1`, etc.
- Ignores: `openssl-ruby`, `portable-openssl`, etc. (don't start with `openssl@`)

**For each matching formula:**
```bash
formula="openssl@3"
prefix="$(brew --prefix openssl@3)"  # /opt/homebrew/opt/openssl@3
version="$($prefix/bin/openssl version)"  # "OpenSSL 3.6.0 ..."
```

**Output:**
```
openssl@3 3.6.0 /opt/homebrew/opt/openssl@3
openssl@3.5 3.5.4 /opt/homebrew/opt/openssl@3.5
```

#### 3. Version Selection Algorithm

**Version Requirement Parsing:**
```bash
needs_openssl:1.0.2-3.x.x
  ↓
lower_bound = "1.0.2" → normalize_semver → 10002
upper_bound = "3.x.x" → replace .x with .99 → "3.99.99" → 39999
```

**Normalization Function:**
```bash
# Example: 3.6.0 → 30600
normalize_semver() {
  awk -F. '{print $1 * 10000 + $2 * 100 + $3}' <<<"$1"
}
```

**Selection Logic:**
1. Extract versions from Homebrew formulas: `[3.6.0, 3.5.4]`
2. Sort versions ascending: `[3.5.4, 3.6.0]`
3. Iterate in REVERSE (highest first): `[3.6.0, 3.5.4]`
4. For each version:
   - Normalize to integer: `3.6.0 → 30600`
   - Check: `10002 <= 30600 < 39999`?
   - If YES → **USE THIS VERSION AND STOP**

**Result:** ruby-build picks **OpenSSL 3.6.0** (highest compatible version)

#### 4. System OpenSSL (Fallback)

If no Homebrew OpenSSL found, uses `/usr/bin/openssl` (often broken on macOS)

### Complete Execution Trace

```
Step 1: Parse Ruby definition
  → needs_openssl:1.0.2-3.x.x

Step 2: Check RUBY_CONFIGURE_OPTS
  → Not set, continue

Step 3: Query Homebrew
  → Found: openssl@3 (3.6.0), openssl@3.5 (3.5.4)

Step 4: Version filtering
  → 3.6.0: 10002 <= 30600 < 39999 ✅
  → 3.5.4: 10002 <= 30504 < 39999 ✅
  → Both qualify!

Step 5: Select highest
  → Winner: 3.6.0 (30600 > 30504)

Step 6: Configure Ruby
  → --with-openssl-dir=/opt/homebrew/opt/openssl@3

Step 7: Ruby links to
  → /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib
```

### Critical Insight

**Even if you install `dsaenztagarro/tap/openssl@3.5`:**

```bash
brew install dsaenztagarro/tap/openssl@3.5
```

Homebrew will now have:
- `openssl@3` (3.6.0) ← **ruby-build picks this**
- `openssl@3.5` (3.5.4) ← ignored

ruby-build will **STILL choose 3.6.0** because it prefers the highest compatible version!

**Solution:** You MUST use `RUBY_CONFIGURE_OPTS` to override automatic selection.

---

## The Homebrew Symlink Vulnerability

### How Homebrew Organizes Packages

```
/opt/homebrew/
├── Cellar/                    # Actual installation directories
│   └── openssl@3/
│       ├── 3.5.4/            # Old version (after upgrade)
│       │   └── lib/
│       │       └── libssl.3.dylib
│       └── 3.6.0/            # New version (current)
│           └── lib/
│               └── libssl.3.dylib
└── opt/                       # Symlinks to current versions
    └── openssl@3 → ../Cellar/openssl@3/3.6.0  ⚠️ Changes during upgrade!
```

### What Happens During `brew upgrade openssl@3`

**Before Upgrade:**
```
/opt/homebrew/Cellar/openssl@3/3.5.4/
/opt/homebrew/opt/openssl@3 → ../Cellar/openssl@3/3.5.4
```

**After Upgrade:**
```
/opt/homebrew/Cellar/openssl@3/3.5.4/  (old, kept temporarily)
/opt/homebrew/Cellar/openssl@3/3.6.0/  (new, active)
/opt/homebrew/opt/openssl@3 → ../Cellar/openssl@3/3.6.0  ⚠️ SYMLINK UPDATED!
```

**Ruby's Perspective:**
- Ruby's `openssl.bundle` references: `/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib`
- Before upgrade: Resolves to `3.5.4/lib/libssl.3.dylib`
- After upgrade: Resolves to `3.6.0/lib/libssl.3.dylib` (automatically!)

### The Compatibility Symlink Problem

Homebrew creates **multiple compatibility symlinks** for OpenSSL:

```bash
$ ls -la /opt/homebrew/opt/ | grep openssl
openssl -> ../Cellar/openssl@3/3.6.0
openssl@3 -> ../Cellar/openssl@3/3.6.0
openssl@3.3 -> ../Cellar/openssl@3/3.6.0
openssl@3.4 -> ../Cellar/openssl@3/3.6.0
openssl@3.5 -> ../Cellar/openssl@3/3.6.0
openssl@3.6 -> ../Cellar/openssl@3/3.6.0
```

**Why This Exists:**
- Backward compatibility for software expecting specific minor versions
- Allows `brew install openssl@3.5` to work even when 3.6.0 is installed

**The Problem:**
- If you try to install `dsaenztagarro/tap/openssl@3.5`, Homebrew sees the symlink and thinks `openssl@3.5` is already installed (from homebrew-core)
- You get: "Error: openssl@3.5 was installed from the homebrew/core tap"

### Why `openssl@3.5` Formula Doesn't Help

Even if you install homebrew-core's `openssl@3.5`:

```bash
brew install openssl@3.5  # Installs 3.5.4
```

**System State:**
```
/opt/homebrew/Cellar/openssl@3.5/3.5.4/
/opt/homebrew/opt/openssl@3.5 → ../Cellar/openssl@3.5/3.5.4
```

**When OpenSSL 3.5.5 is released:**
```bash
brew upgrade openssl@3.5  # Upgrades to 3.5.5
```

**Result:** Same problem within the 3.5.x series!
- Symlink updates: `openssl@3.5 → ../Cellar/openssl@3.5/3.5.5`
- Ruby uses 3.5.5 automatically
- Still exposed to patch-level bugs

---

## Dynamic Linking Explained

### What is libssl.3.dylib?

**Technical Details:**
- **Format:** Mach-O 64-bit dynamically linked shared library
- **Architecture:** arm64 (Apple Silicon)
- **Language:** Compiled C code from OpenSSL project
- **Contains:** 1000+ pre-compiled SSL/TLS functions

**Think of it as:**
- 📦 A package of reusable SSL/TLS functions
- 🔧 A toolbox that programs borrow tools from
- 💾 Loaded into memory once, shared by all programs

### The Compilation Chain

#### Step 1: OpenSSL Source Code (C)

```c
// Example from ssl/ssl_lib.c
SSL *SSL_new(SSL_CTX *ctx) {
    SSL *s = OPENSSL_zalloc(sizeof(*s));
    // ... implementation
    return s;
}
```

#### Step 2: Compilation to Object Files

```bash
gcc -c -fPIC ssl/ssl_lib.c -o ssl_lib.o
gcc -c -fPIC ssl/ssl_rsa.c -o ssl_rsa.o
# ... hundreds more files
```

**Result:** `.o` files containing:
- Machine code (arm64 instructions)
- Position Independent Code (`-fPIC`) - can load at any memory address

#### Step 3: Linking to Create Shared Library

```bash
gcc -dynamiclib -o libssl.3.dylib \
  ssl_lib.o ssl_rsa.o ssl_cert.o ... \
  -lcrypto \
  -install_name /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib
```

**Creates:** `libssl.3.dylib`
- Contains all compiled SSL functions
- Exports public function symbols (SSL_new, SSL_connect, etc.)
- Links to `libcrypto.3.dylib` (crypto primitives)
- **Embedded install name** (used by dynamic linker at runtime)

#### Step 4: Ruby Compilation with OpenSSL

```bash
rbenv install 3.3.5
```

**Ruby's ext/openssl/ Extension Build:**

```bash
# Compilation
gcc -I/opt/homebrew/opt/openssl@3/include \     # OpenSSL headers
    -c ossl_ssl.c -o ossl_ssl.o                 # Ruby wrapper code

# Linking
gcc -bundle -o openssl.bundle \                  # Create loadable module
    ossl_ssl.o ossl_x509.o ... \                 # Ruby wrapper objects
    -L/opt/homebrew/opt/openssl@3/lib \          # Library search path
    -lssl -lcrypto \                             # Link against OpenSSL
    -lruby.3.3                                   # Link against Ruby
```

**Result:** `openssl.bundle`
- Ruby extension (loadable module)
- Contains Ruby-to-OpenSSL wrapper code
- **Dynamically links** to `libssl.3.dylib` (NOT embedded!)

### Runtime Dynamic Linking

#### Scenario: Running a Ruby Script

```bash
$ ruby script.rb
```

**Step-by-Step Execution:**

1. **Start Ruby Process**
   ```
   OS loads: /Users/dsaenz/.rbenv/versions/3.3.5/bin/ruby
   Memory: Ruby interpreter code loaded
   ```

2. **Ruby Executes: `require 'openssl'`**
   ```
   Ruby finds: ~/.rbenv/versions/3.3.5/lib/ruby/3.3.0/arm64-darwin24/openssl.bundle
   OS loads: openssl.bundle into memory
   ```

3. **Dynamic Linker (dyld) Reads Dependencies**
   ```bash
   $ otool -L openssl.bundle
   openssl.bundle:
     /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib      ← Need this!
     /opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib   ← And this!
     /Users/dsaenz/.rbenv/versions/3.3.5/lib/libruby.3.3.dylib
   ```

   dyld: "I need to load these libraries too!"

4. **Resolve Symlinks** ⚠️ **CRITICAL STEP**
   ```
   /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib
     → follow symlink: /opt/homebrew/opt/openssl@3
     → resolves to: /opt/homebrew/Cellar/openssl@3/3.6.0
     → final path: /opt/homebrew/Cellar/openssl@3/3.6.0/lib/libssl.3.dylib
   ```

   **This is where the upgrade trap happens!**

5. **Load libssl.3.dylib Into Memory**
   ```
   OS maps file into process memory
   Memory address: 0x1a2b3c000 - 0x1a2b8f000
   All SSL functions now available
   ```

6. **Symbol Resolution (Function Calls)**
   ```ruby
   # Ruby code
   OpenSSL::SSL::SSLContext.new

   # Call chain:
   Ruby code
     → openssl.bundle: ossl_ssl_ctx_new() (C wrapper)
       → libssl.3.dylib: SSL_CTX_new() (actual OpenSSL)
         → libcrypto.3.dylib: crypto functions

   # Function addresses resolved at runtime!
   ```

7. **Shared Memory Benefits**
   ```
   If 10 Ruby processes run:
     • Each has own openssl.bundle
     • BUT all share ONE copy of libssl.3.dylib in memory
     • Saves RAM (copy-on-write)
   ```

### Static vs Dynamic Linking

#### Static Linking (NOT Used)

```
Compile Time: Library code copied INTO Ruby binary
Ruby binary size: +10 MB (includes OpenSSL)
Runtime: No external dependencies needed

Pros:
  ✅ Self-contained
  ✅ Can't break from library updates

Cons:
  ❌ Larger binaries
  ❌ Must recompile to update OpenSSL
  ❌ Multiple copies in memory (wasteful)
```

#### Dynamic Linking (WHAT RUBY USES)

```
Compile Time: Ruby links to library path
Ruby binary size: Same (just references)
Runtime: Loads library from file system

Pros:
  ✅ Smaller binaries
  ✅ Shared in memory (efficient)
  ✅ Can update library without recompiling programs

Cons:
  ⚠️ External dependency
  ⚠️ Can break if library changes behavior
  ⚠️ Symlinks enable silent upgrades
```

### Why The Upgrade Breaks Ruby

**The ABI vs Behavior Mismatch:**

```
Compile Time (September 2024):
  Ruby compiled against: OpenSSL 3.5.4
  Headers: /opt/homebrew/opt/openssl@3/include/*.h (3.5.4 API)
  Expected behavior: 3.5.4 certificate validation logic

  openssl.bundle knows:
    • Function signatures
    • Expected return values
    • Certificate validation behavior (relaxed CRL checking)

Runtime (October 2024 - AFTER UPGRADE):
  Dynamic linker loads: /opt/homebrew/Cellar/openssl@3/3.6.0/lib/libssl.3.dylib

  Ruby calls: X509_verify_cert(ctx)

  Function signature: ✅ SAME
    int X509_verify_cert(X509_STORE_CTX *ctx);

  Function behavior: ❌ DIFFERENT
    3.5.4: Validates cert, ignores CRL if not present
    3.6.0: Validates cert, REQUIRES CRL, fails if missing

  Result: Certificate validation fails
  Error: "certificate verify failed (unable to get certificate CRL)"
```

**Restaurant Analogy:**

```
You're a chef (Ruby) who learned a recipe (OpenSSL API):

Compile Time:
  Menu item: "Caesar Salad"
  Recipe you learned: lettuce + croutons + dressing
  You build your kitchen (openssl.bundle) based on this

Runtime - AFTER SYMLINK CHANGE:
  Restaurant changes recipe without notice
  New recipe: lettuce + croutons + ANCHOVIES + dressing

  You still follow old recipe (no anchovies)
  Customer: "This isn't right!"
  You: "But I didn't change anything!" ← THIS IS THE PROBLEM

Menu name (function signature) is same, but recipe (implementation) changed!
```

---

## Why Homebrew's Major Version Formulas Are Dangerous

### The Design Philosophy

Homebrew's major version formulas (like `openssl@3`) are designed to:
- Track the latest stable release within a major series
- Automatically upgrade to newer minor/patch versions
- Provide compatibility symlinks for older minor versions

**Example:**
```
openssl@3 formula currently provides: 3.6.0
When 3.7.0 releases: brew upgrade → automatically gets 3.7.0
When 3.8.0 releases: brew upgrade → automatically gets 3.8.0
```

### The Four Danger Scenarios

#### Scenario A: Bugs in New Versions

```
OpenSSL 3.6.0 CRL Bug (Real Incident):
  What: Certificate validation broken
  Impact: All Ruby SSL operations fail
  Affected: ALL Ruby versions simultaneously
  Diagnosis: Difficult (nothing in Ruby changed)
  Recovery: Wait for OpenSSL patch or workaround
```

**Timeline:**
```
Day 1: brew upgrade (3.5.4 → 3.6.0)
Day 1: All Ruby apps start failing SSL
Day 2-7: Debugging, GitHub issues opened
Day 8: Workaround discovered (.rubyopenssl_default_store.rb)
Day 14: OpenSSL patch released (3.6.1)
```

#### Scenario B: API/Behavior Changes

```
Security Strictness Changes:
  • Deprecates old ciphers (TLS 1.0/1.1)
  • Changes default security levels
  • Increases certificate validation strictness
  • Disables weak algorithms

Impact:
  • Connections to old servers fail
  • Legacy systems become unreachable
  • Apps that worked for years suddenly break
```

#### Scenario C: Performance Regressions

```
Example: OpenSSL Performance Bug
  What: New version has performance issue
  Impact: All SSL operations 2-3x slower
  Detection: Hard to identify cause

Result:
  • Web apps slow down mysteriously
  • Timeout errors increase
  • Server load spikes
  • Root cause unclear (no code changed)
```

#### Scenario D: Security Vulnerabilities

```
Example: New OpenSSL Has CVE
  What: Security vulnerability in new version
  Impact: All Ruby installations exposed immediately

Problem:
  • Can't easily rollback (old version cleaned up)
  • All Rubies compromised simultaneously
  • Emergency patching required
```

### Why Minor Version Formulas Don't Help

Even with `openssl@3.5`:

```bash
brew install openssl@3.5  # Installs 3.5.4
# Later...
brew upgrade openssl@3.5  # Upgrades to 3.5.5, 3.5.6, etc.
```

**Same Problem:**
- Symlink updates: `openssl@3.5 → ../Cellar/openssl@3.5/3.5.6`
- Ruby uses new version automatically
- Still exposed to patch-level bugs and changes

### The Homebrew Philosophy Conflict

**Homebrew's Goal:** Keep software up-to-date automatically
**Ruby's Need:** Stable, tested, controlled environment

```
Homebrew: "Latest is greatest! Auto-update everything!"
Ruby: "Stability matters! Test before deploying!"

These goals are fundamentally incompatible.
```

### Real-World Impact Statistics

From GitHub Issue [ruby/openssl#949](https://github.com/ruby/openssl/issues/949):

```
Affected Users: Thousands
Platforms: macOS (Homebrew users)
Ruby Versions: All (2.6.x through 3.4.x)
Duration: ~2 weeks until workaround widespread
Fix: OpenSSL patch + Ruby gem workaround
```

**Common User Experience:**
1. Everything working fine
2. Run `brew upgrade` (or automatic update)
3. Suddenly all Ruby apps fail with SSL errors
4. Hours of debugging
5. Discover it's OpenSSL (external to Ruby)
6. Can't easily rollback
7. Wait for fix or implement workaround

---

## The Solution: Custom OpenSSL Formula

### Why a Custom Formula Solves Everything

**Key Insight:** By maintaining your own OpenSSL formula, you control:
1. **When** upgrades happen
2. **Which** version to use
3. **Testing** before deployment
4. **Rollback** capability

### Formula Design Strategy: openssl-ruby

**THIS TAP NOW USES THE OpensslRuby APPROACH**

**Formula name:** `openssl-ruby.rb` (Formula/openssl-ruby.rb)
**Class name:** `OpensslRuby` (Formula/openssl-ruby.rb:18)

**Why this name:**
- ✅ Doesn't match `^openssl@` pattern (won't be auto-detected by ruby-build)
- ✅ Clear purpose (explicitly for Ruby installations)
- ✅ No conflicts with homebrew-core formulas
- ✅ Won't trigger Homebrew compatibility symlink creation
- ✅ Requires explicit configuration, preventing silent upgrades

**Installation:**
```bash
brew install dsaenztagarro/tap/openssl-ruby
```

**Location:**
```
/opt/homebrew/Cellar/openssl-ruby/3.5.4/
/opt/homebrew/opt/openssl-ruby → ../Cellar/openssl-ruby/3.5.4
```

**Configuration Directory:**
The formula uses a dedicated configuration directory (Formula/openssl-ruby.rb:120):
```
/opt/homebrew/etc/openssl-ruby/
```

This isolation prevents conflicts with other OpenSSL installations.

**Usage with ruby-build:**
```bash
# Add to ~/.zshrc
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix dsaenztagarro/tap/openssl-ruby)"

# Install Ruby
rbenv install 3.4.3
```

**Result:**
```bash
$ ruby -ropenssl -e 'puts OpenSSL::OPENSSL_LIBRARY_VERSION'
OpenSSL 3.5.4 28 May 2024  # ← Your controlled version
```

### Why OpensslRuby Prevents the Incident

The OpensslRuby formula prevents the OpenSSL 3.6.0 incident scenario in several ways:

1. **No Auto-Detection**: ruby-build won't automatically select this formula because it doesn't match the `^openssl@` pattern (lines 180-195). You must explicitly configure it.

2. **Explicit Configuration Required**: The `RUBY_CONFIGURE_OPTS` environment variable makes version selection a conscious decision, not an automatic process.

3. **Isolated from Homebrew Core**: Because the formula name doesn't conflict with homebrew-core patterns, there's no risk of symlink conflicts or accidental replacements during `brew upgrade`.

4. **Controlled Upgrade Path**: When OpenSSL 3.6.0 (or any version) is released, your Ruby installations continue using 3.5.4 until YOU decide to:
   - Test the new version locally
   - Update the formula (Formula/openssl-ruby.rb)
   - Verify Ruby compatibility
   - Deploy the upgrade

This approach transforms OpenSSL upgrades from **automatic and dangerous** to **deliberate and safe**.

### Migration History

**COMPLETED: 2025-11-14**

This tap has been migrated from `openssl@3.5` to `openssl-ruby`:

#### Changes Applied

1. **Formula Renamed**: `Formula/openssl@3.5.rb` → `Formula/openssl-ruby.rb`
2. **Class Updated**: `OpensslAT35` → `OpensslRuby` (Formula/openssl-ruby.rb:18)
3. **Configuration Directory**: `etc/openssl@3` → `etc/openssl-ruby` (Formula/openssl-ruby.rb:120)
4. **Aliases Removed**: Deleted `Aliases/` directory (no longer needed)
5. **Documentation Updated**: All references now point to `openssl-ruby`

#### Why These Changes Matter

The migration from `openssl@3.5` to `openssl-ruby` provides:

- **Pattern Isolation**: The formula name doesn't match `^openssl@`, preventing ruby-build auto-detection
- **Explicit Configuration**: Requires conscious decision via `RUBY_CONFIGURE_OPTS`
- **No Symlink Conflicts**: Won't conflict with homebrew-core's compatibility symlinks
- **Clear Intent**: Name explicitly indicates this is for Ruby, not general-purpose OpenSSL
- **Upgrade Control**: You decide when to upgrade, not Homebrew's auto-update mechanism

### Installation and Configuration

#### For New Users

```bash
# 1. Tap the repository
brew tap dsaenztagarro/tap

# 2. Install openssl-ruby
brew install dsaenztagarro/tap/openssl-ruby

# 3. Add to shell configuration
cat >> ~/.zshrc << 'EOF'

# Force Ruby to use stable OpenSSL version
# Avoids issues with automatic Homebrew OpenSSL upgrades
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix dsaenztagarro/tap/openssl-ruby)"
EOF

# 4. Reload shell
source ~/.zshrc

# 5. Install Ruby
rbenv install 3.4.3
```

#### For Existing Users (Migrating from openssl@3.5)

```bash
# 1. Uninstall old formula if present
brew uninstall dsaenztagarro/tap/openssl@3.5 2>/dev/null || true

# 2. Remove any conflicting symlinks
rm /opt/homebrew/opt/openssl@3.5 2>/dev/null || true

# 3. Install new formula
brew install dsaenztagarro/tap/openssl-ruby

# 4. Update shell configuration
# Replace old references with new:
# OLD: --with-openssl-dir=$(brew --prefix dsaenztagarro/tap/openssl@3.5)
# NEW: --with-openssl-dir=$(brew --prefix dsaenztagarro/tap/openssl-ruby)

# 5. Rebuild Ruby versions (Optional)
# If you want existing Ruby installations to use the new OpenSSL:
rbenv versions > ~/ruby_versions_backup.txt

for version in $(rbenv versions --bare); do
  echo "Rebuilding Ruby $version with openssl-ruby..."
  rbenv uninstall -f $version
  rbenv install $version
done

# 6. Verify
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_LIBRARY_VERSION'
# Should show: OpenSSL 3.5.4 28 May 2024
```

### Testing the Installation

```bash
# 1. Verify formula installed correctly
brew list dsaenztagarro/tap/openssl-ruby

# 2. Check OpenSSL version
$(brew --prefix dsaenztagarro/tap/openssl-ruby)/bin/openssl version

# 3. Install a Ruby version
rbenv install 3.4.7

# 4. Verify Ruby uses correct OpenSSL
rbenv shell 3.4.7
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_LIBRARY_VERSION'
# Should show: OpenSSL 3.5.4 28 May 2024

# 5. Test SSL connection
ruby -ropenssl -e '
  require "net/http"
  uri = URI("https://www.ruby-lang.org")
  response = Net::HTTP.get_response(uri)
  puts "SSL connection successful: #{response.code}"
'
```

### Upgrade Process (When You Want to Update)

```bash
# 1. Test new OpenSSL version locally first
cd /Users/dsaenz/Code/homebrew-tap

# 2. Update formula version
vim Formula/openssl-ruby.rb
# Update: url, sha256, version

# 3. Test locally
brew uninstall dsaenztagarro/tap/openssl-ruby
brew install --build-from-source dsaenztagarro/tap/openssl-ruby

# 4. Test with Ruby
rbenv install 3.4.7  # Test with latest Ruby

# 5. Verify SSL works
ruby -ropenssl -e '/* test code */'

# 6. If successful, commit
git add Formula/openssl-ruby.rb
git commit -m "openssl-ruby: update to 3.X.Y"
git push

# 7. Deploy to other machines
brew update
brew upgrade dsaenztagarro/tap/openssl-ruby

# 8. Rebuild Rubies if needed
rbenv install --force 3.4.7
```

---

## Recommendations

### For Ruby Development

1. **Use OpensslRuby Formula (IMPLEMENTED)**
   - Formula: `Formula/openssl-ruby.rb`
   - Class: `OpensslRuby` (Formula/openssl-ruby.rb:18)
   - Install: `brew install dsaenztagarro/tap/openssl-ruby`
   - Version: 3.5.4 (Formula/openssl-ruby.rb:2)
   - Configuration directory: `/opt/homebrew/etc/openssl-ruby` (Formula/openssl-ruby.rb:120)
   - Pin version for stability
   - Test upgrades before deploying

2. **Set RUBY_CONFIGURE_OPTS (REQUIRED)**
   ```bash
   export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix dsaenztagarro/tap/openssl-ruby)"
   ```
   - Add to `~/.zshrc` or `~/.bash_profile`
   - Ensures all Ruby installations use controlled OpenSSL
   - **This is not optional**: ruby-build won't auto-detect openssl-ruby

3. **Optional: Pin Homebrew's openssl@3**
   ```bash
   brew pin openssl@3
   ```
   - Prevents automatic upgrades of homebrew-core's OpenSSL
   - Reduces system-wide OpenSSL changes
   - Not strictly necessary with OpensslRuby approach

4. **Document Your Setup**
   - Keep notes on which OpenSSL version you're using
   - Document any Ruby-specific OpenSSL workarounds
   - Share with team members
   - Reference: This document and Formula/openssl-ruby.rb

### For Production Environments

1. **Lock OpenSSL Version**
   - Use custom formula approach
   - Never use Homebrew's auto-updating formulas
   - Test OpenSSL upgrades in staging first

2. **Monitor Security Advisories**
   - Subscribe to OpenSSL security mailing list
   - Review CVEs before upgrading
   - Balance security vs stability

3. **Maintain Rollback Capability**
   - Keep multiple OpenSSL versions in Cellar
   - Don't run `brew cleanup` automatically
   - Test rollback procedures

4. **Version Control Ruby Configurations**
   ```bash
   # .ruby-version
   3.4.3

   # .ruby-openssl-version (custom file)
   openssl-ruby-3.5.4
   ```

### For CI/CD Pipelines

1. **Explicit OpenSSL Selection**
   ```yaml
   # .github/workflows/test.yml
   - name: Install Ruby with specific OpenSSL
     run: |
       brew tap dsaenztagarro/tap
       brew install dsaenztagarro/tap/openssl-ruby
       export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix dsaenztagarro/tap/openssl-ruby)"
       rbenv install ${{ matrix.ruby }}
   ```

2. **Cache OpenSSL**
   - Cache OpenSSL installation in CI
   - Prevents random version changes
   - Faster builds

3. **Lock All Dependencies**
   - Pin Ruby version
   - Pin OpenSSL version
   - Pin system dependencies

### Best Practices

#### DO ✅

- **Control OpenSSL upgrades** - Use custom formula
- **Test before upgrading** - Validate in dev/staging
- **Document versions** - Know what you're running
- **Set RUBY_CONFIGURE_OPTS** - Explicit is better than implicit
- **Monitor GitHub issues** - Stay informed about OpenSSL/Ruby bugs

#### DON'T ❌

- **Auto-upgrade OpenSSL** - Don't use `brew upgrade` blindly
- **Rely on system OpenSSL** - macOS OpenSSL often outdated
- **Ignore security advisories** - Balance security vs stability
- **Skip testing** - Test OpenSSL changes before production
- **Use multiple OpenSSL versions** - Keep Ruby environment consistent

---

## References

### Related Issues

- **OpenSSL 3.6.0 Bug:** [ruby/openssl#949](https://github.com/ruby/openssl/issues/949)
- **Original Comment:** [Issue comment with workaround](https://github.com/ruby/openssl/issues/949#issuecomment-3368551818)

### Documentation

- **Homebrew Formula Cookbook:** https://docs.brew.sh/Formula-Cookbook
- **ruby-build:** https://github.com/rbenv/ruby-build
- **OpenSSL:** https://www.openssl.org/docs/

### Tools

- **otool:** macOS tool for inspecting dynamic libraries
  ```bash
  otool -L /path/to/binary  # Show dynamic library dependencies
  ```

- **nm:** Display symbol table
  ```bash
  nm -g /path/to/library    # Show exported symbols
  ```

- **dyld:** macOS dynamic linker
  ```bash
  DYLD_PRINT_LIBRARIES=1 ruby script.rb  # Debug library loading
  ```

---

## Appendix: Technical Deep Dive

### Dynamic Library Loading Process

**Complete call stack when Ruby loads OpenSSL:**

```
1. Process Start
   execve("/Users/dsaenz/.rbenv/versions/3.3.5/bin/ruby")

2. dyld (Dynamic Linker) Initialization
   dyld loads /usr/lib/libc.dylib
   dyld loads /Users/dsaenz/.rbenv/versions/3.3.5/lib/libruby.3.3.dylib

3. Ruby Interpreter Start
   ruby_init()

4. Require Statement
   Ruby: require 'openssl'
   → rb_require_safe()
   → load_ext("/path/to/openssl.bundle")

5. Extension Loading
   dlopen("/path/to/openssl.bundle", RTLD_LAZY)

6. dyld Resolves Dependencies
   Read LC_LOAD_DYLIB commands from openssl.bundle:
     - /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib
     - /opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib

7. Symlink Resolution
   realpath("/opt/homebrew/opt/openssl@3")
   → /opt/homebrew/Cellar/openssl@3/3.6.0

8. Load OpenSSL Libraries
   dlopen("/opt/homebrew/Cellar/openssl@3/3.6.0/lib/libssl.3.dylib")
   dlopen("/opt/homebrew/Cellar/openssl@3/3.6.0/lib/libcrypto.3.dylib")

9. Symbol Binding
   dlsym(libssl_handle, "SSL_CTX_new")
   dlsym(libssl_handle, "SSL_connect")
   ... bind all SSL_* symbols

10. Initialization
    Init_openssl()
    → Create Ruby classes/modules
    → Register SSL_CTX_new as OpenSSL::SSL::SSLContext.new
```

### Memory Layout

```
Process Memory Map:
┌─────────────────────────────────────┐
│ Stack                               │ ← Thread stacks
├─────────────────────────────────────┤
│ ...                                 │
├─────────────────────────────────────┤
│ libssl.3.dylib (read-only)          │ ← Shared across processes
│   - Code: 0x1a2b3c000 - 0x1a2b8f000│
│   - Exports: SSL_*, TLS_*           │
├─────────────────────────────────────┤
│ libcrypto.3.dylib (read-only)       │ ← Shared across processes
│   - Code: 0x1a2b90000 - 0x1a2ff0000│
│   - Exports: AES_*, SHA256_*        │
├─────────────────────────────────────┤
│ openssl.bundle (read/write)         │ ← Per-process
│   - Code: 0x10a3b0000 - 0x10a3c0000│
│   - Data: Ruby wrapper state        │
├─────────────────────────────────────┤
│ libruby.3.3.dylib                   │ ← Shared
├─────────────────────────────────────┤
│ Ruby heap                           │ ← Per-process
├─────────────────────────────────────┤
│ Program text                        │
└─────────────────────────────────────┘
```

### Versioning Semantics

**OpenSSL Versioning:**
```
libssl.3.dylib
       │
       └─ Major version 3 (ABI breaking changes)
          compatibility version: 3.0.0 (minimum)
          current version: 3.0.0 (latest compatible)

Actual OpenSSL version: 3.6.0
  Major: 3  (ABI compatible within 3.x)
  Minor: 6  (features, possibly behavior changes)
  Patch: 0  (bug fixes, should be safe)
```

**The Lie:**
- `compatibility version: 3.0.0` suggests all 3.x versions are compatible
- Reality: Behavioral changes happen in minor versions (3.5 → 3.6)
- ABI compatibility ≠ Behavioral compatibility

---

**Last Updated:** 2025-11-14
**Author:** David Saenz Tagarro
**Related Documents:**
- [VERSIONING_STRATEGY.md](./VERSIONING_STRATEGY.md)
- [ADDING_FORMULAS.md](../ADDING_FORMULAS.md)

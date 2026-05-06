# Workflow Fixes Applied

**Date:** 2026-05-06
**Files Modified:**
- `.github/workflows/build-openwrt.yml`
- `.github/actions/generate-config/action.yml`

## Changes Summary

### 1. ✅ Dependency Install Step
- Added `🛠️ Install Dependencies` step after Checkout
- Installs: build-essential, clang, flex, bison, g++, gawk, gcc-multilib, g++-multilib, gettext, git, libelf-dev, libncurses-dev, libssl-dev, python3, python3-distutils, rsync, unzip, zlib1g-dev, file, wget, jq

### 2. ✅ Disk Cleanup Step
- Added `🧹 Free Disk Space` step after dependency install
- Removes: /usr/share/dotnet, /usr/local/lib/android, /opt/ghc
- Runs apt-get clean and shows df -h

### 3. ✅ ccache Restore & Configure
- Added `🗄️ Restore ccache` (actions/cache@v4) before Build
- Added `⚙️ Configure ccache` (max_size=5G, compression=true, level=6)
- Both conditional on `inputs.enable_ccache == 'true'`

### 4. ✅ Password Masking
- Added `echo "::add-mask::${{ inputs.root_password }}"` and `echo "::add-mask::${{ inputs.wifi_password }}"` at the start of both `run:` blocks in generate-config action:
  - `⚙️ Generate .config` step
  - `🔧 Apply System Config` step
- Prevents passwords from leaking in logs

### 5. ✅ Timeout Reduced
- Changed `timeout-minutes: 360` → `timeout-minutes: 180`

### 6. ✅ Concurrency Control
- Added top-level `concurrency:` block before `jobs:`
- Group: `build-${{ inputs.target }}-${{ inputs.subtarget }}`
- `cancel-in-progress: true` to cancel redundant builds

### 7. ✅ Artifact Config Improved
- `if-no-files-found: warn` → `if-no-files-found: error`
- Added `openwrt/.config` and `openwrt/build.log` to upload paths

### 8. ✅ ccache Save Step
- Added `💾 Save ccache` (actions/cache/save@v4) after Build, before Upload
- Conditional: `always() && inputs.enable_ccache == 'true'`
- Ensures ccache is saved even if build fails

## Validation
Both files pass YAML syntax validation via `yaml.safe_load()`.

## Pipeline Order (after changes)
1. 🛎️ Checkout
2. 🛠️ Install Dependencies
3. 🧹 Free Disk Space
4. 📦 Setup Source
5. ⚙️ Generate Config (with password masking)
6. 📋 Config Summary
7. 🗄️ Restore ccache + ⚙️ Configure ccache
8. 🏗️ Build
9. 💾 Save ccache
10. 🔍 Post-Build Check
11. 📊 Build Summary
12. 📄 Generate Manifest
13. 📤 Upload Firmware (with .config + build.log)

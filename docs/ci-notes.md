# CI Notes - AMCoreAudio Fixes

## Problem

The original `AMCoreAudio` pod from `bitgapp` is dead.
The `rnine/SimplyCoreAudio` repository (tag `3.4`) contains the correct code, **BUT** its directory structure changed (`Source/Public/...`) while the podspec remained non-recursive (`Source/*.swift`).
This resulted in an empty `AMCoreAudio` module (no source files compiled) and "Missing module" errors.

## Solution

We use a **local vendored podspec** (`native/AMCoreAudio.podspec`) to strictly define how `AMCoreAudio` 3.4 is built.

### Key Changes

1. **Local Podspec**: `native/AMCoreAudio.podspec` points to `rnine/SimplyCoreAudio` (tag `3.4`) but uses a **recursive glob** (`Source/**/*.{swift,h,m}`) to correctly find all source files.
2. **Podfile**:
    - Points `AMCoreAudio` to the local podspec: `:podspec => './AMCoreAudio.podspec'`.
    - Includes a `post_install` hook to **patch deprecated constants** (`kAudioDevicePropertyDeviceIsAlive` -> `kAudioObjectPropertyOwnedObjects`) for macOS 15 SDK compatibility.
3. **Xcode Settings**:
    - Forces `DEFINES_MODULE = YES` and `CLANG_ENABLE_MODULES = YES`.
    - Disables `SWIFT_INSTALL_OBJC_HEADER` for this pod to avoid umbrella header conflicts.

## Verification

- Local build: `pod install` should fetch the source files into `Pods/AMCoreAudio/Source/Public/...`.
- CI: Build should succeed with Xcode 16.

## Future Maintenance

If `AMCoreAudio` 3.4 becomes obsolete, migrate to `SimplyCoreAudio` v4+ (requires code changes/renaming).

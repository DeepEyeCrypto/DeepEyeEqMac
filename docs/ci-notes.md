# CI Notes - AMCoreAudio Fixes

## Problem

The original `AMCoreAudio` pod from `bitgapp` is no longer available.
Replacing it directly with `SimplyCoreAudio` (v4+) breaks existing imports and potentially API usage in DeepEyeEqMac.

## Solution

We use the original `AMCoreAudio` version 3.4, but fetched from `rnine/SimplyCoreAudio` repository (tag `3.4`) which preserves the module structure.

### Key Changes

1. **Podfile**: Points `AMCoreAudio` to `https://github.com/rnine/SimplyCoreAudio.git` (tag `3.4`).
2. **Xcode 16 / macOS 15 Compatibility**:
    - `DEFINES_MODULE = YES` forced for AMCoreAudio.
    - `CLANG_ENABLE_MODULES = YES`.
    - `SWIFT_INSTALL_OBJC_HEADER = NO`.
3. **API Patching**:
    - A `post_install` hook automatically patches deprecated CoreAudio constants (`kAudioDevicePropertyDeviceIsAlive` -> `kAudioObjectPropertyOwnedObjects`, etc.) in the downloaded pod source.

## Future Maintenance

If `AMCoreAudio` 3.4 becomes too difficult to maintain, a full migration to `SimplyCoreAudio` v4+ (and renaming all imports/types) will be required.

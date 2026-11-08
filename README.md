# Wave Gore Cleanup — v0.1.0 (source prototype)

Small **UnrealScript mutator for Killing Floor 2** that cleans visible corpse and gore effects when each wave begins. Intended for the `(W4)` servers, but **do not install this unwhitelisted prototype on a ranked public server yet**.

## What it does

- The server mutator creates one owner-relevant, replicated helper for each joining player.
- Each helper watches `KFGameReplicationInfo.bWaveStarted` and `WaveNum` on that player's machine.
- On the first observed tick of a new wave, it clears the local dead-body pool, persistent blood splats, temporary blood decal pools where `Reset()` works, and cosmetic giblets.
- It does **not** destroy weapon pickups, cash or ammo.
- It does **not** call `EnableCheats` or use cheat-console commands.

## Status / constraints

**Prototype only: not compiled or tested against the user's installed Windows KF2 SDK.** The script interfaces were checked against KF2 UnrealScript source, but compilation and in-game validation are still required.

A newly compiled custom mutator is **not automatically whitelisted**. Ordinary launch via `?Mutator=WaveGoreCleanup.WaveGoreCleanupMutator` can make a server unranked and stop perk XP progression. It is not enough to say that the code only changes graphics. There is no promise that this will remain ranked under SafeMutLoader or Unofficial KF2 Patch. Do not deploy to servers 1 or 2 while public players are active.

Testing full multiplayer deployment later also requires the custom `.u` package to be delivered to each game client (normally via a Steam Workshop item); merely copying it to the dedicated server does not guarantee clients receive it.

## Windows SDK preparation (safe for active servers)

Extract this archive anywhere on the development PC. In PowerShell, from the extracted folder:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\setup-and-build.ps1
```

This copies `.uc` sources into the installed KF2 SDK's `Development\Src` directory (the one `KFEditor make` uses):

```text
<SDK installation folder>\Development\Src\WaveGoreCleanup\Classes\
```

It preserves your existing `KFEditor.ini` sections and package registrations. Existing source and editor config files are backed up with a `.bak` suffix before changing.

Then, after confirming that the KF2 SDK and `KFEditor.exe` are installed:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\setup-and-build.ps1 -Build
```

If autodetection fails, pass the game+SDK root via `-SdkDir 'F:\Steam\steamapps\common\killingfloor2'` (adjust the exact folder name as appropriate).

Expected output:

```text
%USERPROFILE%\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script\WaveGoreCleanup.u
```

### If the build fails

Capture the actual UnrealScript compiler errors before changing implementation. Do not blindly alter the public server launch scripts. Check especially whether your SDK exposes `DecalManager.Reset()` and the native gore-manager methods.

## Compilation note

First user SDK build: **0 errors and 1 warning** (`bBlockPlayers=false` unsupported default). The unsupported property has been removed. Recompile and test the new code locally; compilation alone does not validate multiplayer behavior.

## Local-only smoke test

After building and setting up a **separate nonranked sandbox** where the package is visible to the game client, load:

```text
open KF-Spillway?Game=KFGameContent.KFGameInfo_Survival?Difficulty=0?GameLength=0?Mutator=WaveGoreCleanup.WaveGoreCleanupMutator
```

Kill a few zeds, leave visible blood/corpses, finish the wave, then observe the beginning of the next wave. The cleaner should run once, then new gore should continue working during the wave.

Check KF2 client/server logs for:

```text
[Wave Gore Cleanup] Mutator initialized (v0.1.0)
[Wave Gore Cleanup] Client helper created for
[Wave Gore Cleanup] Local gore cleanup completed
```

The first two are **server** messages; the third is a **client** message.

## Compatibility and next steps

1. Compile the UnrealScript package and fix any SDK-specific errors.
2. Validate actual corpse/blood cleanup locally, including temporary decals and client join-in-progress.
3. Test with two clients; confirm weapons dropped by `DropAllWepsOnDeath=1` survive cleanup.
4. Determine a verified ranked-compatible deployment route; do not assume it works merely because the UI still displays a ranked badge.
5. Only after controlled tests, consider `W4 / #2` deployment; keep `W4 / #1` untouched without a separate request.

## Reference API locations

- [KF2 `KFGoreManager.uc`](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/KFGame/Classes/KFGoreManager.uc)
- [KF2 `KFCheatManager.uc` implementation of ClearCorpses/ClearSplatters](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/KFGame/Classes/KFCheatManager.uc)
- [KF2 `KFGameReplicationInfo.uc` wave flags](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/KFGame/Classes/KFGameReplicationInfo.uc)
- [KF2 `DecalManager.uc`](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/Engine/Classes/DecalManager.uc)

No files in `X:\server\` are touched by `setup-and-build.ps1`.

## Rename from W4WaveCleanup

The internal UnrealScript package and both classes are now named `WaveGoreCleanup`. The setup script migrates an existing `ModPackages=W4WaveCleanup` entry in your local `KFEditor.ini` (with a backup) and builds `WaveGoreCleanup.u`. If you copied the old package to a test server previously, remove its old reference **only in the sandbox after stopping it**. This script does not touch any dedicated server.

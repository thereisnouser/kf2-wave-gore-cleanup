# Wave Gore Cleanup — v0.1.0 (source prototype)

Small **UnrealScript mutator for Killing Floor 2** that cleans visible corpse and gore effects when each wave begins. Intended for the `(W4)` servers, but **do not install this unwhitelisted prototype on a ranked public server yet**.

## What it does

- The server mutator creates one owner-relevant, replicated helper for each joining player.
- Each helper watches `KFGameReplicationInfo.bWaveStarted` and `WaveNum` on that player's machine.
- On the first observed tick of a new wave, it clears the local dead-body pool, persistent blood splats, temporary blood decal pools where `Reset()` works, and cosmetic giblets.
- It does **not** destroy weapon pickups, cash or ammo.
- It does **not** call `EnableCheats` or use cheat-console commands.

## Status / constraints

**Standalone and single-client dedicated-server test passed (2026-11-10 through 2026-11-12):** The KF2 SDK compiled the package; a standalone Spillway test visually confirmed blood and corpse removal and logged two local cleanup events (58.88 s and 122.49 s). On the W4 #2 dedicated server, the server log confirms both mutators loaded, initialization, player connection, and a helper for `KFPlayerController_0`. The tester visually confirmed cleanup at the start of wave 2. This was a loopback connection with the client already having the `.u` package; **a second remote client, automatic package distribution, dropped-weapon persistence, and ranked/XP compatibility remain untested**.

A newly compiled custom mutator is **not automatically whitelisted**. Ordinary launch via `?Mutator=WaveGoreCleanup.WaveGoreCleanupMutator` can make a server unranked and stop perk XP progression. It is not enough to say that the code only changes graphics. There is no promise that this will remain ranked under SafeMutLoader or Unofficial KF2 Patch. Do not deploy to servers 1 or 2 while public players are active.

Testing full multiplayer deployment later also requires the custom `.u` package to be delivered to each game client (normally via a Steam Workshop item); merely copying it to the dedicated server does not guarantee clients receive it.

## Windows SDK preparation (safe for active servers)

Extract this archive anywhere on the development PC. In PowerShell, from the extracted folder:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\setup-and-build.ps1
```

This copies `.uc` sources into the user KF2 source directory, confirmed to be the effective source location in this SDK installation:

```text
%USERPROFILE%\Documents\My Games\KillingFloor2\KFGame\Src\WaveGoreCleanup\Classes\
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

With `-Build`, the script moves the previous package into `WaveGoreCleanupBuildBackups` under the user KFGame directory, checks the compiler exit code, and requires a fresh nonempty package and a fresh log reporting zero errors and zero warnings.

### Prepare a distribution package

With the game and SDK closed, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-and-build.ps1 -Build -Brew
```

This performs a fresh compile, then runs `KFEditor brewcontent -platform=PC WaveGoreCleanup -log`. It requires a newly written, nonempty published package and copies it into `dist/BrewedPC/Script/WaveGoreCleanup.u`, checking the SHA256 hash. Only use the distribution package after this command completes successfully. This step does not upload to Steam or touch dedicated servers. The brew workflow is based on Trader Anywhere; the first local compile and brew have now succeeded.

### Steam Workshop (maintainers)

A fresh compile and brew completed on 2026-11-25. The distribution package was reported as 11961 bytes, SHA256 `9E0011B9623C9B2C7D80336AE1E82D724D110ED3559084C830D96E2BCBABA9A1`. The SDK also brewed other installed packages, but only WaveGoreCleanup is copied into the distribution directory.

Supply a PNG preview smaller than 1 MB (default: `icon.png` in the repository root). To prepare an isolated Workshop upload without publishing:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\publish-workshop.ps1 -SdkDir 'F:\Steam\steamapps\common\killingfloor2'
```

The script stages only the distribution binary, preview and metadata in a new directory under `dist/`. Verify the output hash and metadata before first publication. To publish, rerun with `-Upload` while signed into Steam and type `PUBLISH` when prompted. Do not use first publication to update an existing item. A local upload-attempt record prevents accidental retries; check Steam for an existing item even if the uploader reports an error. This script is adapted from Trader Anywhere and still requires a local staging test.

### If the build fails

Capture the actual UnrealScript compiler errors before changing implementation. Do not blindly alter the public server launch scripts. Check especially whether your SDK exposes `DecalManager.Reset()` and the native gore-manager methods.

## Compilation note

The original SDK build reported an unsupported `bBlockPlayers=false` default. On 2026-11-25, the stale copy in the user `KFGame/Src` directory was identified as the cause of the repeated warning. After correcting source synchronization and moving the old compiled package aside, the SDK compiled and saved `WaveGoreCleanup.u` with **0 errors and 0 warnings**. A further fresh build using the updated automatic rebuild script reported the same compiler result. The new controller filter has not yet been tested in a running multiplayer game.

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

1. Completed: SDK compilation and standalone visual cleanup on Spillway across at least two wave starts.
2. Completed: W4 #2 dedicated server with Unofficial KF2 Patch and one loopback-connected client; cleanup observed at start of wave 2.
3. Next: test a **second remote client**, confirm package delivery and join-in-progress, and verify cleanup on both screens.
4. Confirm dropped weapons (`DropAllWepsOnDeath=1`) survive cleanup and cosmetic decals do not persist incorrectly.
5. Determine a verified ranked-compatible deployment route and test actual perk XP; a ranked badge alone is not proof. The localhost log includes `Skipping online subsystem authentication` and `Can't start an online game in state 0`.
6. Implemented and compiled: restrict the helper loop to `KFPlayerController` to exclude WebAdmin's `TeamChatProxy`. Confirm this in the next dedicated-server runtime test.
7. Keep W4 #1 untouched. Do not open W4 #2 to ordinary players until ranked/XP behavior and client delivery are proven.

### Other log messages observed during dedicated-server test

- Server was able to load the previously installed Unofficial KF2 Patch, but Workshop update of item `2875147606` failed.
- `UKFP_UI_HUD` and later `ENV_StaticShadow_Test_MESH` missing-asset warnings appeared. These are distinct from our successful gore cleanup and may need separate investigation.
- A server log cannot show `Local gore cleanup completed` because that log line is written client-side.

## Reference API locations

- [KF2 `KFGoreManager.uc`](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/KFGame/Classes/KFGoreManager.uc)
- [KF2 `KFCheatManager.uc` implementation of ClearCorpses/ClearSplatters](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/KFGame/Classes/KFCheatManager.uc)
- [KF2 `KFGameReplicationInfo.uc` wave flags](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/KFGame/Classes/KFGameReplicationInfo.uc)
- [KF2 `DecalManager.uc`](https://github.com/GenZmeY/KF2-Game-Scripts/blob/master/Engine/Classes/DecalManager.uc)

No files in `X:\server\` are touched by `setup-and-build.ps1`.

## Rename from W4WaveCleanup

The internal UnrealScript package and both classes are now named `WaveGoreCleanup`. The setup script migrates an existing `ModPackages=W4WaveCleanup` entry in your local `KFEditor.ini` (with a backup) and builds `WaveGoreCleanup.u`. If you copied the old package to a test server previously, remove its old reference **only in the sandbox after stopping it**. This script does not touch any dedicated server.

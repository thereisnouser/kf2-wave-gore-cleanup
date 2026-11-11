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

The first user SDK build succeeded with **0 errors and 1 warning** (`bBlockPlayers=false`, an unsupported default). The unsupported property was removed. A subsequent SDK run reported **0 errors and 0 warnings**, although it said `No scripts need recompiling` (so that particular run was not a fresh recompilation). The standalone game run confirmed that local cleanup works.

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
6. Clean up the server helper loop so it ignores WebAdmin's `TeamChatProxy` (observed in the log). This is cosmetic/efficiency work and has not yet been committed to code.
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

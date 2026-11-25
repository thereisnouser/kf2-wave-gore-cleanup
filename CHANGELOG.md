# Changelog

## Unreleased (planned 0.1.1)

- Restrict helper creation to `KFPlayerController`, excluding WebAdmin's `TeamChatProxy` by class hierarchy.
- Synchronize sources into the user `KFGame/Src` directory instead of the SDK development tree; stale user sources caused the old unsupported-property warning.
- Back up the previous compiled package before each build and verify exit code, output freshness, and a fresh compiler log with zero errors and warnings.
- Add optional `-Brew` distribution build with fresh output and SHA256 verification (runtime validation pending).
- Fresh SDK compilation confirmed on 2026-11-25; multiplayer runtime validation of the filter remains pending.

## 0.1.0 — experimental source prototype

- Created stand-alone `WaveGoreCleanup` package with server-side client-helper provisioning.
- Implemented per-client, wave-start detection through replicated `KFGameReplicationInfo` properties.
- Calls local gore-manager operations to remove corpses and clear blood; destroys cosmetic giblets.
- Added safe Windows SDK preparation/build script and test plan.
- Local SDK compilation succeeded. Standalone KF-Spillway gameplay test on 2026-11-10 confirmed visible gore cleanup at wave start; `Launch.log` recorded two local cleanup events (58.88 s and 122.49 s).
- First dedicated-server test passed on W4 #2 (single localhost-connected client): server log confirmed both mutators, player connection and client-helper creation; blood and corpses visibly disappeared at the beginning of wave 2.
- Remaining validation: second network client and package distribution, join-in-progress, dropped weapon persistence, ranked/XP behavior.
- Known minor issue: the helper is also created for WebAdmin `TeamChatProxy_0` (planned filter).

- Renamed package, UnrealScript classes and source distribution from W4 Wave Cleanup to Wave Gore Cleanup; behavior unchanged.

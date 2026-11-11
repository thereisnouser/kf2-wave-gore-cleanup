# Changelog

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

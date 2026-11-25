# KF2 Wave Gore Cleanup

**Automatically clear accumulated blood and corpses at the beginning of each wave in Killing Floor 2.** Wave Gore Cleanup removes old gore effects on each connected client's machine while allowing new effects to appear during combat.

## ✨ Features

- **Automatic wave-start cleanup** — no commands or extra keybinds.
- **Corpse removal** — clears the local dead-body pool and cosmetic giblets.
- **Blood removal** — clears persistent splats and temporary blood decal pools.
- **Normal combat effects** — new blood and corpses can appear again during the wave.
- **Non-invasive cleanup** — does not intentionally target dropped weapons, ammo or cash; pickup persistence still needs an in-game test.
- **No cheats required** — uses the game's gore-manager APIs rather than cheat console commands.

## 🎮 How to use

Join a server running the mutator and play normally. At the start of a new wave, the mod automatically clears accumulated gore. There is nothing to activate manually.

## 📦 Installation

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3845518084) (item ID: `3845518084`). Subscribing downloads the Workshop content but does not enable the mutator on a dedicated server. The downloaded package and remote client delivery still need verification.

> **Experimental build.** A public release ZIP and a verified automatic installer are not available yet. Workshop distribution and multiplayer compatibility are still being tested. Use a separate modded/Unranked test server, not a live Ranked server.

### 1. Find your server folder

If your Windows dedicated server is currently running:

1. Press **Ctrl + Shift + Esc** to open Task Manager.
2. Open the **Details** tab, find `KFServer.exe`, right-click it and choose **Open file location**.
3. Go up two folders from `Binaries\Win64` to find the server root.

If it is stopped, use the installation folder specified in SteamCMD's `force_install_dir` or your hosting panel.

### 2. Prepare the mod for testing

Build the package using the Development instructions below. The resulting file is `dist/BrewedPC/Script/WaveGoreCleanup.u`.

For a Windows test server, stop all instances sharing its installation and copy the package to `KFGame\BrewedPC\WaveGoreCleanup.u`. This follows the installation layout used by Trader Anywhere; the newly brewed Wave Gore Cleanup package has not yet been tested with this distribution workflow. Keep a backup of any existing copy. Connecting clients must also have access to the matching package.

### 3. Start the server with the mod enabled

Back up your existing server launcher, then add the mutator to the map URL. Keep all existing server options, ports and other mods.

**Example — no other mutators:**

```text
KF-Spillway?Game=KFGameContent.KFGameInfo_Survival?Mutator=WaveGoreCleanup.WaveGoreCleanupMutator
```

**Example — another mutator is already enabled:**

```text
KF-Spillway?Mutator=ExampleMod.ExampleMutator,WaveGoreCleanup.WaveGoreCleanupMutator
```

Do not add a second `?Mutator=` option. `ExampleMod.ExampleMutator` represents your existing mod. If you use a hosting panel, edit its mutator list or startup arguments instead.

### 4. Check that it works

Join your test server, finish a wave and watch the beginning of the next wave. Old blood and corpses should disappear, while new gore should continue to appear during combat.

Look for these messages in the server log:

```text
[Wave Gore Cleanup] Runtime initialized (v0.1.1)
[Wave Gore Cleanup] Client helper created for
```

The cleanup confirmation is written to the **client** log:

```text
[Wave Gore Cleanup] Local gore cleanup completed
```

### Uninstall

Stop the test server, remove only `WaveGoreCleanup.WaveGoreCleanupMutator` from the launcher (or the whole `?Mutator=` option if it is the only mod), then restart. Delete the unused package only once no server uses it.

## ⚠️ Compatibility

- Intended for modded/Unranked Survival servers. Not officially whitelisted by Tripwire; Ranked progression is not guaranteed.
- Standalone and single-client dedicated-server cleanup were visually verified with the original prototype.
- An initial dedicated test with Unofficial KF2 Patch succeeded. The WebAdmin controller filter compiled in the first Workshop build. The new Safe Mut Loader entry point and runtime are awaiting compilation and multiplayer verification.
- Remote multiplayer, join-in-progress, automatic client package delivery, pickup persistence and actual perk XP remain unverified.

## 🛠️ Development

### Requirements

- Killing Floor 2 and Killing Floor 2 SDK, launched at least once.
- Windows PowerShell.

### Building

From the repository root, with the game and SDK closed:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup-and-build.ps1 `
  -SdkDir '<Killing Floor 2 SDK directory>' -Build -Brew
```

The script synchronizes the UnrealScript sources into the user `KFGame\Src` directory, registers the package, backs up the previous compiled file and requires a fresh compilation with zero errors and warnings. It then brews and hash-checks `dist/BrewedPC/Script/WaveGoreCleanup.u`.

Omit `-Brew` to compile only, or omit both switches to prepare the SDK sources and configuration only. No dedicated server files are modified.

### Steam Workshop (maintainers)

Place the approved preview in `icon.png` at the repository root (or pass `-PreviewPath` to a PNG smaller than 1 MB). Prepare an isolated staging directory without uploading:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\publish-workshop.ps1 `
  -SdkDir '<Killing Floor 2 SDK directory>'
```

First publication succeeded on 2026-11-25: [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3845518084) (ID `3845518084`). The `-Upload` option is now disabled to prevent duplicate items. Updating the existing item by Workshop ID is not implemented yet. Preparation-only mode remains available.

### Local testing

Launch KF2 with `-useunpublished -log` and run the following in the game console:

```text
open KF-Spillway?Game=KFGameContent.KFGameInfo_Survival?Difficulty=0?GameLength=0?Mutator=WaveGoreCleanup.WaveGoreCleanupMutator
```

Finish a wave, observe the cleanup, then confirm that new gore appears during combat. Also verify that dropped items remain available and that multiple clients see the cleanup.

### Implementation

The entry-point `WaveGoreCleanupMutator` supports conventional loading and advertises `WaveGoreCleanupRuntime` to Safe Mut Loader. The server-only runtime creates a replicated, owner-relevant helper for each `KFPlayerController`. This change is awaiting SDK and runtime verification. The client-side `WaveGoreCleanupClient` checks replicated wave state every 250 ms and uses `KFGoreManager` and the local decal pools to remove old gore. It does not use cheat commands.

See [development notes](docs/development-notes.md) for build history, SDK troubleshooting, reference APIs and the remaining validation plan.

## 🔗 Links

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3845518084) · [Report an issue](https://github.com/thereisnouser/kf2-wave-gore-cleanup/issues) · [Changelog](CHANGELOG.md) · [Development notes](docs/development-notes.md)

---

*Made by thereisnouser*

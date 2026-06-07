# Changes in this revision (13.1)

A code-quality and robustness pass over the scripts. No change to the core
intent of the tool; the focus is on correctness, safety, and reversibility.

## Script_Run.bat (rewritten)
- **Arguments forwarded through elevation** — `/r`, `/a`, `/s`, etc. now survive
  the UAC relaunch (previously they were dropped).
- New `/restore`, `/n` / `/noreboot`, and `/?` arguments; flags and the action
  argument can be combined in any order.
- New **[R] Restore** menu entry.
- Removed the dead `pushd "%CD%"` and the duplicate `regedit` pass (changes are
  now applied once, via PowerRun when available, otherwise plain `regedit`, with
  a warning if PowerRun is missing).
- Fixed the misleading "Removing Windows Security UWP App…" message on the
  antivirus-only path (it never touched the app).
- Canonical `if errorlevel N` syntax.
- All steps are logged to `DefenderRemover.log`.
- Reboot is no longer forced (`/f` dropped); a 60-second cancellable countdown
  is used and can be skipped with `/noreboot`.

## files_removal.bat (rewritten)
- Uses environment variables (`%ProgramData%`, `%ProgramFiles%`,
  `%ProgramW6432%`, `%ProgramFiles(x86)%`) instead of hard-coded `C:\`.
- `if exist` guards so missing paths are skipped quietly.
- Grants rights to the **Administrators SID** (`S-1-5-32-544`) instead of the
  localized name "administrators".
- Logs each action; reports folders it could not fully remove.
- No longer calls bare `exit` (which closed the parent window).

## RemoveSecHealthApp.ps1 (rewritten)
- Fixed real bugs:
  - `"$store\Deprovisioned\$appx.PackageFamilyName"` did not expand the
    property — now uses the resolved family name.
  - the installed-packages loop referenced a stale `$PackageFamilyName` from the
    provisioned loop — now uses the package's own family name.
  - the skip-list (`$skip`) was never defined — now a real `-Skip` parameter.
- Added `#Requires -RunAsAdministrator`, comment-based help, parameters
  (`-PackagePattern`, `-Skip`), and error handling. Replaced the `!1`/`!0` and
  `>''` idioms with readable equivalents.

## Restore_Defender/ (new)
- `Restore_Defender.reg` removes the disabling policy/override keys and
  re-enables SmartScreen, notifications and the Settings page.
- `Restore_Defender.bat` resets service start values, re-adds the startup entry,
  runs `DISM /RestoreHealth` + `sfc /scannow` to restore deleted services/files,
  and re-registers the Windows Security UI.
- Documented limitations (component store must be intact; Tamper Protection is
  manual).

## ISO_Maker/
- Added `defender.vbs` — a readable, commented copy of the script the unattend
  builds inline during WinPE, as a maintainable source of truth.
- Added the same explanatory comment to all three identical unattend copies
  (media-root `autounattend.xml` and the Panther `autounattend.xml` /
  `unattend.xml`) and a maintainer section in the ISO README, noting they must be
  kept in sync. The working inline generator was intentionally left in place, and
  all three files were re-validated as well-formed XML.

## README.md
- Documented the real argument set and the restore flow; fixed several typos.

# ❌️ Defender Remover / Defender Disabler

<a href="https://github.com/ionuttbara/windows-defender-remover">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="./site-res/darkmode.png">
        <img alt="Defender Remover" src="./site-res/lightmode.png">
    </picture>
</a>

##  Project Modules

For specific details on the sub-components, please check:

* **[💿 ISO Maker](./ISO_Maker/README.md)** - Create a custom Windows ISO with Defender disabled.
* **[🛡️ Remove Defender Engine](./Remove_Defender/README.md)** - Remove the antivirus core and services.
* **[🖥️ Remove Security App](./Remove_SecurityComp/README.md)** - Remove the Windows Security UI.

---

## ❓️ What does the app do?

This application removes / disables Windows Defender, including the Windows Security App, Windows Virtualization-Based Security (VBS), Windows SmartScreen, Windows Security Services, Windows Web-Threat Service, Windows File Virtualization (UAC), Microsoft Defender App Guard, Microsoft Driver Block List, System Mitigations and the Windows Defender page in the Settings App on Windows 10 or later.


## ❓️ What components are removing?

### Removing Security Components
    This script removes/disables following security components:
        - support for Windows Security Center including Windows Security Center Service (wscsvc), Windows Security Service (SgrmBroker, Sgrm Drivers) which are needed to run Windows Security App.
        - virtualization support.
            - Hypervisor startup (this fixes disablation of Virtualization Based Security, this will auto enable if you use Hyper-V and/or WSL (Windows Subsystem for Linux), WSA (Windows Subsystem for Android))
            - LUA (disables File Virtualization and User Account Control, which will run all apps with administrator privileges (also fixes old app errors))
            - Exploit Guard (something about Exploits)
            - Windows Smart Control
            - Tamper Protection (for Windows 11 21H2 or earlier)
        - SecHealthUI (Windows Security UWP App)
        - SmartScreen
        - Pluton Support and Pluton Services Support
        - System Mitigations
          - "Services Mitigations" (search on admx.help for more informations, its policy)
          - Spectre and Meltdown Mitigation (for get +30% performance on old Intel CPUs)
        - Windows Security Section from Settings App.

### Removing Antivirus Components
    This script forcibly removes the following antivirus components:
      - Windows Defender Definition Update List (this will disable updating definitions of Defender because its removed)
      - Windows Defender SpyNet Telemetry
      - Antivirus Service
      - Windows Defender Antivirus filter and windows defender rootkit scanner drivers
      - Antivirus Scanning Tasks
      - Shell Associations (Context Menu)
      - Hides Antivirus Protection section from Windows Security App.

## ♻️ Restoring Defender

This tool can attempt to undo its changes:

```bat
Script_Run.bat /restore
```

This removes the disabling policy keys, resets the Defender service start
values, and uses `DISM /RestoreHealth` + `sfc /scannow` to bring back service
definitions and files from the Windows component store. It is **best-effort** —
if you also removed the component store, or after a complete removal, a
Windows in-place repair / reinstall may be required. Tamper Protection must be
re-enabled manually in the Windows Security app. See
[Restore_Defender](./Restore_Defender/README.md) for details and limitations.

## 📃 Instructions

> [!NOTE]
> A System Restore point or full backup is strongly recommended before you run the script, especially if you are unsure what it does.

1. Download the packed script from [Releases](https://github.com/ionuttbara/windows-defender-remover/releases)
2. Run the ".exe" as administrator
3. Follow the instructions displayed

OR

you can use git

```
git clone [https://github.com/ionuttbara/windows-defender-remover.git](https://github.com/ionuttbara/windows-defender-remover.git)
cd windows-defender-remover
Script_Run.bat
```


OR

you can use download entire source code
1. Download the source code from [Releases](https://github.com/jbara2002/windows-defender-remover/releases).
2. Choose the file **Source Code(.zip)** from last version and download it.
3. Unarchive the file into a folder and run the Script_Run.bat.

![cli](https://github.com/drunkwinter/windows-defender-remover/assets/38593134/46007191-0a65-43c2-b451-a993ff90e00e)

You can file an [issue](https://github.com/ionuttbara/windows-defender-remover/issues) if you experience any problems.

## 📃 Automation of the script

`Script_Run.bat` accepts command-line arguments, so it can run unattended. The
arguments are forwarded through the UAC elevation prompt, so they work even when
the script has to relaunch itself as administrator.

| Argument | Action |
| --- | --- |
| `/r` | Remove Defender antivirus **and** the Windows Security App |
| `/a` | Remove Defender antivirus only (keeps the Security App) |
| `/s` | Remove leftover Defender files (run after `/r` or `/a`) |
| `/restore` | Restore / re-enable Defender (best-effort) |
| `/n` or `/noreboot` | Apply changes but do not reboot automatically |
| `/?` or `/help` | Show usage |

```bat
:: Remove everything, without an automatic reboot
Script_Run.bat /r /noreboot
```

> All actions are written to `DefenderRemover.log` next to the script.


## Disable or Remove Windows Defender *Application Guard Policies* (advanced)

If you have any problems when opening an app (*extremely rare*) and get the message "The app can not run because Device Guard" or "Windows Defender Application Guard Blocked this app", you have to remove 4 files with the same name, from different locations.


- In EFI Partition

```PowerShell
Remove-Item -LiteralPath "$((Get-Partition | ? IsSystem).AccessPaths[0])Microsoft\Boot\WiSiPolicy.p7b"
```

- In Code Integrity Folder

```PowerShell
Remove-Item -LiteralPath "$env:windir\System32\CodeIntegrity\WiSiPolicy.p7b"
```

- In Windows Folder

```PowerShell
Remove-Item -LiteralPath "$env:windir\Boot\EFI\wisipolicy.p7b"
```

- In WinSxS Folder

```PowerShell
Remove-Item -Path "$env:windir\WinSxS" -Include *winsipolicy.p7b* -Recurse
```

## Creating an ISO with Windows Defender and Services disabled

You can create an ISO with Windows Defender and Security Services disabled. It's easy — this is a file which can help you.
Here are the rules:
1. Mount the ISO and extract it into location.
2. Open the **sources** folder and create the **$OEM$** folder. (this is needed to run the DefenderRemover part in OOBE).
3. Open the **$OEM$** folder and create the folder with **$$** name.
4. Open the **$$** folder and create the folder with **Panther** name.
5. Open the **Panther** folder.
   The path it shown like to
    **%location of extracted ISO%\sources\$OEM$\$$\Panther\**
6. Download the unattend.xml file from the repo's ISO_Maker folder and put it in the Panther folder.
7. Save this as a bootable ISO. (For now the script can't do this automatically, but it will in a next version.)
    

## ❓ Frequently Asked Questions
#### ⭕ How to remove Windows Security Center / Windows SecurityApp from PC without downloading Script?
Paste this code into a powershell file and after **Run as Administrator**.
```
$remove_appx = @("SecHealthUI"); $provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers; $eol = @()
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store -ea 0 |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageName = $appx.PackageName; $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName 
    ni "$store\Deprovisioned\$PackageFamilyName" -force >''; $PackageFamilyName  
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageName" -force >''} ; $eol += $PackageName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxprovisionedpackage -packagename $PackageName -online -allusers >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageFullName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageFullName = $appx.PackageFullName; 
    ni "$store\Deprovisioned\$appx.PackageFamilyName" -force >''; $PackageFullName
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageFullName" -force >''} ; $eol += $PackageFullName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxpackage -package $PackageFullName -allusers >''
  }
}
```

#### ⭕ Why is the downloaded executable being flagged as a virus?

That is a false positive.

Some security apps flag this app as a virus because of the way the ".exe" files are created. Download with **git** or source code .zip will indicate virus-free.
Starting with Defender 12.6.x , some versions are considered as virus, some are not (its a bug from me, so do not file for this).

#### ⭕ Why is the patch not working when Windows is updated?

Windows Update includes a ```Intelligence Update``` which blocks certain actions and modifies Windows Defender/Security policies.
If the script is not working for you, check if you have the Windows Security Intelligence Update installed. If you do, disable tamper protection, and re-run the script.

#### ⭕ How to use the package remover without downloading the executable from the release?

Run the desired ".bat" file from cmd with PowerRun (by dragging to the executable). You must reboot for the changes to take effect.

#### ⭕ How to disable VBS if the removal script does not work

Disable with this command and reboot.

```
bcdedit /set hypervisorlaunchtype off
```
After that you will not be able to use virtual machines.  

#### ⭕  Why  VBS is keeping enabling on Windows 11?

By default the script is disabling VBS to gain performance in your system. The factors which is keeping VBS enabled is Windows Virtualization.  
    
Apps and features which is used by Windows Virtualization:  

- Windows Subsystem for **Android**/**Linux** - HyperV Virtual Machine
- <a href="https://apps.microsoft.com/detail/9n0tn65p5bf6?hl=en-US&gl=US" target="_blank">Microsoft Emulator</a>  (Windows 10X Emulator which you can find in Microsoft Store)
- Android Studio integration in Visual Studio or other emulators (for Windows 10 22H2 with the March 2025 Update or newer)

If you open those one of that app mentioned earlier, VBS will be enabled without user intervention. Its needed to run Virtual Machine engine. If you don't use any virtual machine, you can file an Issue at <a href="https://github.com/ionuttbara/windows-defender-remover/issues" target="_blank">here</a>.

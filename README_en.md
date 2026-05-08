# Chrome GenAI Hardening

Hardening toolkit for Google Chrome on Windows, macOS, and Linux.

This project aims to reduce exposure to Chrome's built-in AI features by applying local Chrome Enterprise policies, cleaning known local AI artifacts, and documenting observed behavior around GenAI, OptimizationGuide, and Screen AI components.

The goal is defensive: regain control over browser-side AI features, limit unwanted automatic downloads, document low-visibility local components, and generate verification reports that can be used in a privacy hardening workflow.

## Current project status

The project now covers four main areas:

```text
1. Chrome Enterprise anti-AI policies.
2. Cleanup of local GenAI / OptimizationGuide models.
3. Cleanup and documentation of the local screen_ai / Screen AI / OCR component.
4. Experimental blocking of screen_ai folder recreation.
```

Scripts are available for Windows, macOS, and Linux.

The persistence blocking documented here mainly applies to Windows through a local ACL rule applied to the `screen_ai` folder.

## Verification context

Local tests were performed on a Windows machine with Google Chrome:

```text
Version 148.0.7778.97 (Official Build) (64-bit)
```

The analyzed path was:

```text
%LOCALAPPDATA%\Google\Chrome\User Data\
```

During the analysis, a local folder named `screen_ai` was identified. It contains files such as:

```text
_metadata
aksara
gocr
chrome_screen_ai.dll
files_list_main_content_extraction.txt
files_list_ocr.txt
gocr_mobile_chrome_multiscript_2024_q4_engine.binarypb
manifest.json
README.md
screen2x_config.pbtxt
screen2x_model.tflite
THIRD_PARTY_LICENSES
```

These files indicate the presence of a local component related to Chrome Screen AI, OCR, and main content extraction.

## Local observation about screen_ai

During a local test, the Windows hardened script removed the following folder:

```text
AppData\Local\Google\Chrome\User Data\screen_ai
```

Removed size:

```text
106.88 MB
```

Report excerpt:

```text
Removed: C:\Users\██████████\AppData\Local\Google\Chrome\User Data\screen_ai (106.88 MB)
```

After manual or scripted deletion, Chrome was observed recreating the `screen_ai` folder on the next browser launch, with a different identifier or version number.

This suggests that `screen_ai` may be managed as a local component that Chrome can recover or reinstall automatically, likely through its internal component or update mechanism.

Deletion alone may therefore not be enough to prevent it from returning.

## Suspected time window

Based on local observations, the persistence or installation of `screen_ai` appears to have occurred within a window between the Chrome updates dated:

```text
April 2, 2026
April 20, 2026
```

This time range remains a working hypothesis based on the timestamps and visible artifacts on the analyzed machine.

One particularly confusing point is that the timestamp shown in the persistence artifacts appears to correspond to a time when the machine was powered off and therefore offline, according to the local observation.

This does not, by itself, conclusively prove the exact installation time. Timestamps can be inherited from an archive, a manifest, a downloaded component, delayed extraction, an update mechanism, or another internal Chrome process.

However, the observation is important to document because it reinforces the core issue of this project: a sensitive local component capable of OCR and content extraction can appear inside the Chrome profile without a clear, explicit, and understandable user-facing consent flow in the standard browser UI.

In this project, this is treated as a user control issue and a consent transparency concern, especially when the component is recreated after deletion.

## screen_ai persistence

The `ScreenAIInstallState` source code shows that Screen AI has a dedicated installation state on the browser side.

The observed behavior is consistent with this logic:

```text
- an internal client can indicate that Screen AI is needed.
- Chrome updates a last usage timestamp.
- Chrome may trigger DownloadComponent().
- if OCR or Main Content Extraction features are enabled, Chrome may attempt to recover the component.
- a new version may be downloaded while an older version already exists.
- the new version may be used after the next browser restart.
```

The sensitive point is therefore not only Screen AI's OCR capability, but also the fact that it is managed as a recoverable Chrome component.

Without a clear interface allowing the user to understand, refuse, or durably disable this behavior, this raises transparency and control concerns.

## Current persistence blocking

At the current stage, `screen_ai` persistence has been locally cut through a simple rule in the PowerShell script:

```powershell
if ($BlockRecreation) {
    Bloquer-RecreationScreenAI -Actions $Actions
}
```

This option is enabled with:

```powershell
-BlockRecreation
```

The principle is:

```text
1. remove the existing screen_ai folder.
2. recreate an empty screen_ai folder.
3. modify the Windows ACL on that folder.
4. remove write permissions for the current user account.
5. keep Administrator/SYSTEM rights.
```

The goal is to prevent Chrome, running in the user context, from freely writing or recreating the content of the `screen_ai` folder.

Example:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Disable-Chrome-ScreenAI-Hardening.ps1 -ForceCloseChrome -BlockRecreation
```

To remove the block:

```powershell
.\Disable-Chrome-ScreenAI-Hardening.ps1 -UnblockRecreation
```

Important: this block is experimental. It should not be presented as an absolute guarantee. It cuts the persistence observed locally by blocking write access to the known path, but Chrome or Google may change paths, download mechanisms, or component behavior in future versions.

For caution, the ACL blocking code can be kept as a personal research tool and not published directly if the goal is to avoid misuse or side effects for other users.

## Validation screenshots

### screen_ai folder content

```md
![screen_ai folder content](docs/screenshots/screenai-evidence-1.png)
![recreated screen_ai folder content](docs/screenshots/screenai-evidence-3.png)
```
![recreated screen_ai folder content](docs/screenshots/screenai-evidence-1.png)

![recreated screen_ai folder content](docs/screenshots/screenai-evidence-3.png)

### Local Chrome Screen AI README

The README file inside the component states that Chrome Screen AI provides two on-device features for Chrome and ChromeOS:

![recreated screen_ai folder content](docs/screenshots/screenai-evidence-2.png)


```text
Main Content Extraction
Optical Character Recognition
```

It also states that these features run entirely on device.

## Disclaimer about screen_ai

The `screen_ai` folder was not initially discovered through the article that motivated this project. It was identified later during a deeper analysis of the Chrome user profile.

This component does not appear to be the exact same element as the Gemini Nano / GenAI model discussed in the original article. It appears to be related to Chrome Screen AI, OCR, and main content extraction.

Not everyone will necessarily have this folder. Its presence may depend on Chrome version, release channel, enabled features, experimental flags, staged Google rollouts, user profile state, and usage history.

Chrome channels that may differ include:

```text
Stable
Extended Stable
Beta
Dev
Canary
```

This project does not claim that Chrome permanently analyzes the screen. It documents a local component capable of OCR and content extraction, with low visibility in the standard browser UI, and potentially recreated automatically after deletion.

The main issue is:

```text
low transparency + unclear consent + limited user control + persistence
```

## Chromium source code analysis

The Chromium source code related to Screen AI is located in:

```text
services/screen_ai/
chrome/browser/screen_ai/
```

Links:

```text
https://source.chromium.org/chromium/chromium/src/+/main:services/screen_ai/
https://source.chromium.org/chromium/chromium/src/+/main:chrome/browser/screen_ai/
```

Analyzed elements include:

```text
ScreenAILibraryWrapper
ScreenAILibraryWrapperImpl
ScreenAILibraryWrapperFake
ScreenAIService
ScreenAIInstallState
screen_ai_service_impl
screen_ai_ocr_perf_test
BUILD.gn
include_rules
OWNERS / chromium-accessibility
```

The analysis shows that Chromium has an architecture able to:

```text
- load a local Screen AI library from disk.
- provide model files to that library.
- initialize an OCR pipeline.
- perform OCR on images.
- extract the main content of a page.
- manipulate accessibility trees.
- use visual annotations through protobuf.
- record usage and performance metrics.
- use sandboxing on some systems.
- operate with either a real implementation or a fake test implementation.
- manage installation or recovery of the Screen AI component.
```

## What the analysis confirms

The analysis confirms that `screen_ai` is not just a passive folder.

The component is linked to a Chromium architecture capable of:

```text
- loading a local native library.
- using model and configuration files.
- processing images through OCR.
- returning visual annotations.
- analyzing an accessibility tree.
- identifying the main content of a page.
- serving several internal clients.
- being recovered or reinstalled depending on Chrome internal state.
```

Internal clients mentioned in the code include:

```text
PDF Viewer
Local Search
Camera App
Media App
Screenshot Text Detection
Tests
```

## What the analysis does not prove

The analyzed elements do not prove that Chrome permanently analyzes the screen.

They confirm that Chromium has a local service capable of using Screen AI on demand, when certain internal features trigger it.


## Hardening modes

### Targeted mode

Related scripts:

```text
scripts/windows/Disable-Chrome-GenAI.ps1
scripts/macos/Disable-Chrome-GenAI-macOS.sh
scripts/linux/Disable-Chrome-GenAI-linux.sh
```

Main policy:

```text
GenAILocalFoundationalModelSettings = 1
```

### Hardened mode

Related scripts:

```text
scripts/windows/Disable-Chrome-AI-Features.ps1
scripts/macos/Disable-Chrome-AI-Features-macOS.sh
scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

Applied policies:

```text
AIModeSettings                       = 1
CreateThemesSettings                 = 2
DevToolsGenAiSettings                = 2
GeminiActOnWebSettings               = 1
GeminiSettings                       = 1
GenAILocalFoundationalModelSettings  = 1
HelpMeWriteSettings                  = 2
HistorySearchSettings                = 2
SearchContentSharingSettings         = 1
```

The following policy is intentionally not used:

```text
GenAiDefaultSettings
```

### Screen AI Hardening mode

Related script:

```text
scripts/windows/Disable-Chrome-ScreenAI-Hardening.ps1
```

Important options:

```text
-ForceCloseChrome
-BlockRecreation
-UnblockRecreation
-WhatIf
```

## Screen AI Hardening script

`Disable-Chrome-ScreenAI-Hardening.ps1` acts on several levers:

```text
- applying known AI policies.
- backing up existing Chrome policies.
- optionally closing Chrome.
- cleaning the screen_ai folder.
- cleaning the local accessibility.screen_ai.last_used_time preference.
- optionally blocking recreation through Windows ACLs.
```

The persistence blocking logic is based on this block:

```powershell
if ($BlockRecreation) {
    Bloquer-RecreationScreenAI -Actions $Actions
}
```

The block is only applied when the `-BlockRecreation` option is used.

## Usage

### Windows

Run PowerShell as administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-AI-Features.ps1
```

Screen AI hardening with recreation blocking:

```powershell
.\scripts\windows\Disable-Chrome-ScreenAI-Hardening.ps1 -ForceCloseChrome -BlockRecreation
```

Remove the block:

```powershell
.\scripts\windows\Disable-Chrome-ScreenAI-Hardening.ps1 -UnblockRecreation
```

### macOS

```bash
chmod +x scripts/macos/Disable-Chrome-AI-Features-macOS.sh
sudo ./scripts/macos/Disable-Chrome-AI-Features-macOS.sh
osascript -e 'quit app "Google Chrome"'
```

### Linux

```bash
chmod +x scripts/linux/Disable-Chrome-AI-Features-linux.sh
sudo ./scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

## Verification

### chrome://policy

Open:

```text
chrome://policy/
```

Click `Reload policies`.

Expected result:

```text
AIModeSettings                       1    OK
CreateThemesSettings                 2    OK
DevToolsGenAiSettings                2    OK
GeminiActOnWebSettings               1    OK
GeminiSettings                       1    OK
GenAILocalFoundationalModelSettings  1    OK
HelpMeWriteSettings                  2    OK
HistorySearchSettings                2    OK
SearchContentSharingSettings         1    OK
```

### screen_ai

Main Windows path:

```text
%LOCALAPPDATA%\Google\Chrome\User Data\screen_ai
```

If the folder returns after deletion, document:

```text
- date and time.
- size.
- files present.
- component version or identifier.
- action that appears to trigger recreation.
```

## Procmon analysis

Recommended filters:

```text
Process Name is chrome.exe
Path contains screen_ai
Operation is CreateFile
Operation is WriteFile
Operation is SetBasicInformationFile
Operation is CreateFileMapping
```

Goal:

```text
- identify the process recreating the folder.
- identify the exact recreation time.
- identify written files.
- verify whether recreation happens at browser startup.
- find a clean way to prevent reinstallation.
```

## Limitations

Known limitations:

```text
- a web page can display AI-generated content.
- a search engine can display server-side AI results.
- an extension can use its own AI features.
- Google may modify or add policies in future versions.
- some policies may depend on the installed Chrome version.
- screen_ai may be recreated or redownloaded if Chrome considers it necessary.
- ACL blocking is experimental and depends on the currently observed path.
- observed timestamps are not always enough to prove the exact download or extraction time.
```

## Sources

```text
https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/
https://chromeenterprise.google/policies/
https://developer.chrome.com/docs/ai/
https://source.chromium.org/chromium/chromium/src/+/main:services/screen_ai/
https://source.chromium.org/chromium/chromium/src/+/main:chrome/browser/screen_ai/
```

## License

MIT License.

## Author

Project created by Potate_bulle as part of a privacy hardening and defensive Windows, macOS, and Linux administration workflow.

## Quick summary

```text
Goal     : disable Chrome integrated AI features
Systems  : Windows, macOS, Linux
Languages: PowerShell, Bash
Level    : Privacy Hardening
Action   : local policies + local model cleanup + screen_ai + optional ACL blocking
Finding  : screen_ai may be automatically recreated after deletion
Window   : persistence suspected between the April 2, 2026 and April 20, 2026 Chrome updates
Status   : persistence locally cut through -BlockRecreation
```

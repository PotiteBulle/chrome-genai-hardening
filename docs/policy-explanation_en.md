# Chrome Policy Explanation

This document explains the Chrome policies used by the `chrome-genai-hardening` project.

The project is designed to disable Chrome's local AI model, including Gemini Nano / GenAI, as well as several AI features integrated into the browser.

It supports three systems:

```text
Windows
macOS
Linux
```

Each system applies Chrome Enterprise policies in a different way.

```text
Windows : Windows Registry
macOS   : plist file
Linux   : managed policy JSON file
```

## 1. Policy goals

The policies used by this project are intended to:

- Disable the download of the local GenAI / Gemini Nano AI model.
- Disable several AI features integrated into Chrome.
- Reduce unwanted automatic downloads.
- Prevent some browser-side AI integrations.
- Clean up older local AI model files.
- Keep the configuration verifiable through `chrome://policy/`.

## 2. Main policy

The main policy used by this project is:

```text
GenAILocalFoundationalModelSettings = 1
```

This policy tells Chrome not to download the local AI model used by some GenAI features.

It is used in all project modes:

```text
Targeted mode
Hardened mode
Windows
macOS
Linux
```

This is the most important policy for preventing Chrome from using or downloading the local model related to Gemini Nano / GenAI.

## 3. Targeted mode

The targeted mode only applies the main policy:

```text
GenAILocalFoundationalModelSettings = 1
```

This mode is useful when the goal is only to block the local AI model.

Related scripts:

```text
scripts/windows/Disable-Chrome-GenAI.ps1
scripts/macos/Disable-Chrome-GenAI-macOS.sh
scripts/linux/Disable-Chrome-GenAI-linux.sh
```

After applying the policy, verification is done in Chrome through:

```text
chrome://policy/
```

Expected result:

```text
GenAILocalFoundationalModelSettings    1    OK
```

## 4. Hardened mode

The hardened mode applies several Chrome Enterprise policies related to AI features.

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

Related scripts:

```text
scripts/windows/Disable-Chrome-AI-Features.ps1
scripts/macos/Disable-Chrome-AI-Features-macOS.sh
scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

This mode is recommended when the goal is to reduce browser-side Chrome AI features as much as possible.

## 5. Details of hardened mode policies

### AIModeSettings

```text
AIModeSettings = 1
```

This policy disables or limits Chrome AI Mode integrations, including AI Mode entry points when they are available.

### CreateThemesSettings

```text
CreateThemesSettings = 2
```

This policy disables AI theme creation in Chrome.

### DevToolsGenAiSettings

```text
DevToolsGenAiSettings = 2
```

This policy disables GenAI features integrated into Chrome DevTools.

### GeminiActOnWebSettings

```text
GeminiActOnWebSettings = 1
```

This policy disables or limits Gemini's ability to act on web content when this feature is available.

### GeminiSettings

```text
GeminiSettings = 1
```

This policy disables or limits Gemini integration in Chrome.

### GenAILocalFoundationalModelSettings

```text
GenAILocalFoundationalModelSettings = 1
```

This policy prevents the download of the local GenAI / Gemini Nano AI model.

It is the central policy of this project.

### HelpMeWriteSettings

```text
HelpMeWriteSettings = 2
```

This policy disables the AI-based writing assistance feature.

### HistorySearchSettings

```text
HistorySearchSettings = 2
```

This policy disables AI-assisted history search.

### SearchContentSharingSettings

```text
SearchContentSharingSettings = 1
```

This policy limits or disables content sharing with some integrated search or AI features.

## 6. Important note about GenAiDefaultSettings

The following policy is no longer used by this project:

```text
GenAiDefaultSettings
```

Some Chrome installations may ignore this policy when it is configured locally.

In that case, Chrome may show an error in:

```text
chrome://policy/
```

Example error:

```text
Policy ignored because it is not configured by a cloud source.
```

To avoid this error, the project does not apply `GenAiDefaultSettings`.

However, the scripts may remove it if it is already present from an older version of the project.

## 7. Policy locations by system

### Windows

On Windows, policies are written to the Registry:

```text
HKLM:\SOFTWARE\Policies\Google\Chrome
```

PowerShell verification example:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" |
Select-Object `
    AIModeSettings,
    CreateThemesSettings,
    DevToolsGenAiSettings,
    GeminiActOnWebSettings,
    GeminiSettings,
    GenAILocalFoundationalModelSettings,
    HelpMeWriteSettings,
    HistorySearchSettings,
    SearchContentSharingSettings |
Format-List
```

### macOS

On macOS, policies are written to a plist file:

```text
/Library/Managed Preferences/com.google.Chrome.plist
```

The file should be owned by `root:wheel` with appropriate permissions.

The macOS scripts create or update this file automatically.

### Linux

On Linux, policies are written to a managed policy JSON file:

```text
/etc/opt/chrome/policies/managed/
```

For official Google Chrome, files used by the project may include:

```text
/etc/opt/chrome/policies/managed/chrome-genai-hardening.json
/etc/opt/chrome/policies/managed/chrome-no-ai-hardening.json
```

For Chromium, the path may be different:

```text
/etc/chromium/policies/managed/
```

This project primarily targets official Google Chrome.

## 8. Verification after applying policies

After running a script, open Chrome and go to:

```text
chrome://policy/
```

Then click:

```text
Reload policies
```

or the localized equivalent.

For targeted mode, the expected result is:

```text
GenAILocalFoundationalModelSettings    1    OK
```

For hardened mode, the expected result is:

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

The following policy should not appear:

```text
GenAiDefaultSettings
```

## 9. Local model verification

The local model can be checked through:

```text
chrome://on-device-internals/
```

An expected result after applying the hardening may be:

```text
Foundational model state: Not Eligible
Folder size: 0 MiB
enabled by enterprise policy: false
```

This indicates that the local model is not usable by Chrome.

## 10. Local model cleanup

The scripts may search for and remove some folders related to local AI models.

### Windows

```text
%LOCALAPPDATA%\Google\Chrome\User Data\OptGuideOnDeviceModel
%LOCALAPPDATA%\Google\Chrome\OptGuideOnDeviceModel
%LOCALAPPDATA%\Google\Chrome\User Data\OptimizationGuideModelStore
%LOCALAPPDATA%\Google\Chrome\User Data\OptimizationGuidePredictionModels
```

### macOS

```text
~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel
~/Library/Application Support/Google/Chrome/OptimizationGuideModelStore
~/Library/Application Support/Google/Chrome/OptimizationGuidePredictionModels
~/Library/Application Support/Google/Chrome/User Data/OptGuideOnDeviceModel
~/Library/Application Support/Google/Chrome/User Data/OptimizationGuideModelStore
~/Library/Application Support/Google/Chrome/User Data/OptimizationGuidePredictionModels
```

### Linux

```text
~/.config/google-chrome/OptGuideOnDeviceModel
~/.config/google-chrome/OptimizationGuideModelStore
~/.config/google-chrome/OptimizationGuidePredictionModels
~/.config/google-chrome/User Data/OptGuideOnDeviceModel
~/.config/google-chrome/User Data/OptimizationGuideModelStore
~/.config/google-chrome/User Data/OptimizationGuidePredictionModels
```

These paths may change depending on Chrome versions.

## 11. Restore mode

The restore scripts remove the policies applied by the project.

Related scripts:

```text
scripts/windows/Restore-Chrome-GenAI.ps1
scripts/macos/Restore-Chrome-GenAI-macOS.sh
scripts/linux/Restore-Chrome-GenAI-linux.sh
```

Policies removed by restore mode:

```text
AIModeSettings
CreateThemesSettings
DevToolsGenAiSettings
GeminiActOnWebSettings
GeminiSettings
GenAILocalFoundationalModelSettings
HelpMeWriteSettings
HistorySearchSettings
SearchContentSharingSettings
GenAiDefaultSettings
```

`GenAiDefaultSettings` is removed only as cleanup, in case it is still present from an older version of the project.

## 12. Limitations

These policies strongly reduce browser-side Chrome AI features.

However, they cannot guarantee the blocking of all server-side AI content.

Examples:

- A web page can display AI-generated content.
- A search engine can display server-side AI summaries.
- An installed extension can use its own AI features.
- Google may modify or add policies in future Chrome versions.
- Some policies may depend on the exact installed Chrome version.

This project does not replace a complete browser privacy configuration.

## 13. Quick summary

```text
Central policy : GenAILocalFoundationalModelSettings = 1
Targeted mode  : blocks the local AI model
Hardened mode  : blocks several Chrome AI integrations
Windows        : Windows Registry
macOS          : plist file
Linux          : managed policy JSON file
Verification   : chrome://policy/ and chrome://on-device-internals/
```

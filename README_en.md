# Chrome GenAI Hardening

Hardening toolkit for Google Chrome on Windows, macOS, and Linux.

This project allows you to disable the download of the local AI model used by some Chrome GenAI features, including Gemini Nano and embedded models. It also allows you to disable several Chrome AI integrations through local Chrome Enterprise policies available depending on the operating system.

The goal is simple: regain control over Chrome AI features, reduce unwanted automatic downloads, limit browser-side AI integrations, remove already downloaded local model files, and generate verification reports that can be used in a Privacy Hardening workflow.

## Why this project exists

This project was created after reading the following article:

https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/

The article explains that Chrome can locally download a large AI model related to Gemini Nano / GenAI. This repository provides a defensive, documented, and reversible response: use locally available Chrome Enterprise policies to prevent the local model from being downloaded, then clean up any existing local artifacts.

The project was later extended to disable other AI features integrated into Chrome, such as Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI, and some content-sharing features related to AI services.

This project does not attempt to modify Chrome or bypass its protections. It only applies administrator configuration rules.

## Project goals

This toolkit allows you to:

- Disable the download of Chrome's local GenAI / Gemini Nano AI model.
- Disable several AI features integrated into Chrome.
- Apply Chrome Enterprise policies depending on the operating system.
- Remove local folders related to already downloaded AI models.
- Clean up some older rules that may trigger errors in `chrome://policy/`.
- Generate verification reports.
- Provide a clean base for auditing, hardening, and security documentation.

## Supported systems

The project targets three platforms:

```text
Windows
macOS
Linux
```

Each system uses a different method to apply Chrome policies.

```text
Windows : Windows Registry
macOS   : plist file
Linux   : managed policy JSON file
```

## Warning

This project is intended for privacy hardening, system administration, and defensive use.

It does not modify Chrome binaries, bypass security mechanisms, or perform any offensive action.

The scripts only apply local Chrome Enterprise policies and remove local model files when they are present.

Use these scripts only on a machine you own or are authorized to administer.

## Recommended repository structure

```text
chrome-genai-hardening/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── windows/
│   │   ├── Disable-Chrome-GenAI.ps1
│   │   ├── Disable-Chrome-AI-Features.ps1
│   │   └── Restore-Chrome-GenAI.ps1
│   ├── macos/
│   │   ├── Disable-Chrome-GenAI-macOS.sh
│   │   ├── Disable-Chrome-AI-Features-macOS.sh
│   │   └── Restore-Chrome-GenAI-macOS.sh
│   └── linux/
│       ├── Disable-Chrome-GenAI-linux.sh
│       ├── Disable-Chrome-AI-Features-linux.sh
│       └── Restore-Chrome-GenAI-linux.sh
├── docs/
│   ├── policy-explanation.md
└── reports/
    └── example-report.md
```

## Available scripts

### Targeted mode

The targeted mode mainly disables the local GenAI / Gemini Nano AI model.

Related scripts:

```text
scripts/windows/Disable-Chrome-GenAI.ps1
scripts/macos/Disable-Chrome-GenAI-macOS.sh
scripts/linux/Disable-Chrome-GenAI-linux.sh
```

Main policy applied:

```text
GenAILocalFoundationalModelSettings = 1
```

This rule tells Chrome not to download the local AI model used by some GenAI features.

### Hardened mode

The hardened mode disables as many browser-side Chrome AI features as possible.

Related scripts:

```text
scripts/windows/Disable-Chrome-AI-Features.ps1
scripts/macos/Disable-Chrome-AI-Features-macOS.sh
scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

Policies applied by the hardened mode:

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

### Restore mode

The restore mode removes the policies applied by this project in order to return Chrome to its default behavior.

Related scripts:

```text
scripts/windows/Restore-Chrome-GenAI.ps1
scripts/macos/Restore-Chrome-GenAI-macOS.sh
scripts/linux/Restore-Chrome-GenAI-linux.sh
```

## How it works by system

### Windows

On Windows, policies are applied in the Registry:

```text
HKLM:\SOFTWARE\Policies\Google\Chrome
```

The scripts must be run in PowerShell as Administrator.

### macOS

On macOS, policies are applied through a plist file:

```text
/Library/Managed Preferences/com.google.Chrome.plist
```

The scripts must be run with `sudo`.

### Linux

On Linux, policies are applied through a JSON file in Chrome's managed policies directory:

```text
/etc/opt/chrome/policies/managed/chrome-genai-hardening.json
```

The scripts must be run with `sudo`.

Depending on the distribution or the Chrome package type, some paths may vary. For Google Chrome Stable installed from the official package, the recommended path is generally:

```text
/etc/opt/chrome/policies/managed/
```

For Chromium, the path may be different, for example:

```text
/etc/chromium/policies/managed/
```

This project primarily targets Google Chrome.

## Note about GenAiDefaultSettings

The following policy is not used by this project:

```text
GenAiDefaultSettings
```

Some Chrome installations may ignore this rule when it is configured locally. In that case, Chrome may show an error in `chrome://policy/` indicating that the rule is ignored because it is not configured by a cloud source.

To avoid this error, this project does not use `GenAiDefaultSettings`.

However, the scripts may remove this older rule if it is already present on the machine.

## Requirements

### Windows

- Windows 10 or Windows 11.
- Google Chrome installed.
- PowerShell.
- Administrator privileges.

### macOS

- macOS.
- Google Chrome installed.
- Terminal.
- Administrator privileges with `sudo`.

### Linux

- Linux distribution with Google Chrome installed.
- Bash shell.
- Administrator privileges with `sudo`.
- Access to `/etc/opt/chrome/policies/managed/`.

## Installation

Clone the repository:

```bash
git clone https://github.com/PotiteBulle/chrome-genai-hardening
cd chrome-genai-hardening
```

## Usage on Windows

### Targeted mode

Open PowerShell as Administrator, then run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-GenAI.ps1
```

### Hardened mode

Open PowerShell as Administrator, then run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-AI-Features.ps1
```

### Restore

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Restore-Chrome-GenAI.ps1
```

## Usage on macOS

### Targeted mode

```bash
chmod +x scripts/macos/Disable-Chrome-GenAI-macOS.sh
sudo ./scripts/macos/Disable-Chrome-GenAI-macOS.sh
```

### Hardened mode

```bash
chmod +x scripts/macos/Disable-Chrome-AI-Features-macOS.sh
sudo ./scripts/macos/Disable-Chrome-AI-Features-macOS.sh
```

### Restore

```bash
chmod +x scripts/macos/Restore-Chrome-GenAI-macOS.sh
sudo ./scripts/macos/Restore-Chrome-GenAI-macOS.sh
```

After running the script, fully close Chrome:

```bash
osascript -e 'quit app "Google Chrome"'
```

Then relaunch Chrome.

## Usage on Linux

### Targeted mode

```bash
chmod +x scripts/linux/Disable-Chrome-GenAI-linux.sh
sudo ./scripts/linux/Disable-Chrome-GenAI-linux.sh
```

### Hardened mode

```bash
chmod +x scripts/linux/Disable-Chrome-AI-Features-linux.sh
sudo ./scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

### Restore

```bash
chmod +x scripts/linux/Restore-Chrome-GenAI-linux.sh
sudo ./scripts/linux/Restore-Chrome-GenAI-linux.sh
```

After running the script, fully close Chrome and relaunch it.

## What the hardened mode does

The hardened script will:

1. Check administrator privileges.
2. Create the policy directory if needed.
3. Apply several Chrome Enterprise AI policies.
4. Apply `GenAILocalFoundationalModelSettings = 1`.
5. Remove or avoid the older `GenAiDefaultSettings` rule.
6. Search for local folders related to AI models.
7. Remove any matching folders found.
8. Generate a verification report.

## Verification in Chrome

After running the script, open Chrome and go to:

```text
chrome://policy/
```

Then click:

```text
Reload policies
```

or the localized equivalent.

You should see the hardened mode policies with the `OK` status, for example:

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

You should no longer see:

```text
GenAiDefaultSettings
```

## Local model verification

You can also verify the local model state through:

```text
chrome://on-device-internals/
```

After applying the script, the local model may appear as:

```text
Foundational model state: Not Eligible
Folder size: 0 MiB
enabled by enterprise policy: false
```

This indicates that the local GenAI model is not usable by Chrome and that the hardening is correctly applied.

## Generated reports

By default, the scripts generate reports in:

```text
./reports/
```

Examples:

```text
./reports/chrome-genai-policy-check.txt
./reports/chrome-no-ai-hardening-report.txt
./reports/chrome-genai-restore-report.txt
./reports/chrome-genai-policy-check-macos.txt
./reports/chrome-no-ai-hardening-report-macos.txt
./reports/chrome-genai-restore-report-macos.txt
./reports/chrome-genai-policy-check-linux.txt
./reports/chrome-no-ai-hardening-report-linux.txt
./reports/chrome-genai-restore-report-linux.txt
```

Reports may contain:

- Execution date.
- Applied policies.
- Checked paths.
- Performed actions.
- Removed or missing folders.
- Manual verification steps.

## Checked model paths

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

## Why use a policy instead of only deleting files?

Only deleting local files may not be enough.

Chrome may download some components again if an AI feature or an integrated API triggers their use.

The policy-based approach is cleaner because it directly tells Chrome that the local model download is not allowed.

File removal is therefore a complementary cleanup step, but the policy remains the main part of the hardening process.

## Limitations

This project greatly reduces browser-side Chrome AI features, but it cannot guarantee complete blocking of every server-side AI-generated content.

For example:

- A web page can display AI-generated content.
- A search engine can display server-side AI results or summaries.
- An installed extension can use its own AI features.
- Google may modify or add policies in future Chrome versions.
- Some policies may depend on the installed Chrome version.

This project does not replace a full browser privacy configuration.

## Recommended checks

After execution, check:

```text
chrome://policy/
```

```text
chrome://on-device-internals/
```

```text
chrome://flags/
```

In `chrome://flags/`, you can manually search for:

```text
Gemini
GenAI
Nano
Prompt API
Summarization
Writer
Rewriter
Proofreader
```

Then disable experimental AI flags if needed.

## Validation

Validation was performed on a personal Windows machine: Chrome policies related to AI features were successfully applied with the `OK` status in `chrome://policy/`.

The script disables the local GenAI model as well as several Chrome AI integrations, including Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI, and Search Content Sharing.

The local model can also be checked in `chrome://on-device-internals/`, where it should appear as ineligible or absent.

The macOS and Linux versions should be verified in the same way with `chrome://policy/` and `chrome://on-device-internals/`.

## Possible improvements

Possible future improvements:

- Add a WhatIf mode.
- Automatically verify policies after application.
- Add a backup system before modification.
- Add a compatibility table by Chrome version.
- Add specific Chromium support.

## Sources

- Article that motivated the project: https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/
- Chrome Enterprise Policies documentation: https://chromeenterprise.google/policies/
- Chrome Built-in AI documentation: https://developer.chrome.com/docs/ai/

## Contributing

Contributions are welcome.

You can propose:

- New detection paths.
- PowerShell improvements.
- Bash improvements.
- Better documentation.
- Screenshots.
- Example reports.
- Compatibility with other Chromium-based browsers.
- Tests on different Chrome versions.
- Tests on Windows, macOS, and Linux.

## License

This project is licensed under the MIT License.

## Author

Project created by Potate_bulle as part of a privacy hardening and defensive Windows, macOS, and Linux administration workflow.

## Quick summary

```text
Goal      : disable AI features integrated into Chrome
Systems   : Windows, macOS, Linux
Languages : PowerShell, Bash
Level     : Privacy Hardening
Action    : local policies + local model cleanup + reports
```

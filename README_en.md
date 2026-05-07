# Chrome GenAI Hardening

Hardening toolkit for Google Chrome on Windows, macOS, and Linux.

This project disables the download of the local AI model used by some Chrome GenAI features, including Gemini Nano or embedded models. It can also disable several Chrome AI integrations through local Chrome Enterprise policies depending on the operating system.

The project also cleans known local AI artifacts, including folders related to GenAI / OptimizationGuide models and the local `screen_ai` folder, associated with Chrome Screen AI / OCR components.

The goal is simple: regain control over Chrome AI features, reduce unwanted automatic downloads, limit browser-side AI integrations, remove already downloaded model files, clean some local AI components, and generate verification reports for a Privacy Hardening workflow.

## Local Screen AI discovery context

This project was tested on a Windows machine with Google Chrome:

```text
Version 148.0.7778.97 (Official Build) (64-bit)
```

During a deeper manual review of Chrome folders under:

```text
%LOCALAPPDATA%\Google\Chrome\User Data\
```

a local folder named `screen_ai` was identified.

This folder contained files and subfolders such as:

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

## Screen AI validation screenshots

### screen_ai folder content

The following screenshot shows the files found inside the `screen_ai` folder.

![screen_ai folder content](docs/screenshots/screenai-evidence-1.png)

### Chrome Screen AI README

The following screenshot shows the `README.md` file found inside the `screen_ai` folder.

![Chrome Screen AI README](docs/screenshots/screenai-evidence-1.png)

A `README.md` file inside this component states that the Chrome Screen AI library provides two on-device features for Chrome and ChromeOS:

```text
Main Content Extraction
Optical Character Recognition
```

The README also states that these features run entirely on device and do not send data to the network or store it on disk according to that document.

## Disclaimer about screen_ai

The `screen_ai` folder was not initially discovered through the article that motivated this project. It was found later during a deeper analysis of the Chrome profile directory.

This component does not appear to be the exact same element as the Gemini Nano / GenAI model discussed in the original article. It appears to be related to Chrome Screen AI, OCR, and main content extraction.

However, it is still relevant to this project because it is another local component related to automated analysis features present in Chrome.

Important note: not everyone will necessarily have this folder. Some users may have a `screen_ai` folder, while others may not. Its presence can depend on multiple factors, including the Chrome version, the installed release channel, enabled features, experimental flags, staged Google rollouts, the local profile, and usage history.

Chrome channels that may differ include:

```text
Stable
Extended Stable
Beta
Dev
Canary
```

The question remains legitimate: why is this kind of local component not more visible to the user? What level of consent, transparency, and control is actually provided around these features?

This project does not claim to prove malicious intent. It documents a local observation, provides a defensive hardening approach, and leaves the question open.

To be continued.

## Why this project exists

This project was created after reading the following article:

https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/

The article explains that Chrome may locally download a large AI model related to Gemini Nano / GenAI. This repository provides a defensive, documented, and reversible response: use locally available Chrome Enterprise policies to prevent the local model download, then clean up existing local artifacts.

The project was later extended to disable other AI features integrated into Chrome, such as Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI, and some content-sharing features related to AI services.

The project also cleans the `screen_ai` folder when present in the Chrome profile.

## Project goals

This toolkit allows you to:

- Disable the download of Chrome's local GenAI / Gemini Nano AI model.
- Disable several AI features integrated into Chrome.
- Apply Chrome Enterprise policies depending on the operating system.
- Remove local folders related to already downloaded AI models.
- Remove local folders related to `screen_ai` / Screen AI / OCR when present.
- Clean up older rules that may trigger errors in `chrome://policy/`.
- Generate verification reports.
- Create backups before some modifications.
- Provide a clean base for auditing, hardening, and security documentation.

## Supported systems

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

Use these scripts only on a machine you own or are authorized to administer.

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

The targeted mode also cleans known local artifacts:

```text
GenAI / OptimizationGuide
screen_ai / local Screen AI / OCR
```

### Hardened mode

The hardened mode disables as many browser-side Chrome AI features as possible.

Related scripts:

```text
scripts/windows/Disable-Chrome-AI-Features.ps1
scripts/macos/Disable-Chrome-AI-Features-macOS.sh
scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

Policies applied by hardened mode:

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

The hardened mode also cleans known local artifacts:

```text
GenAI / OptimizationGuide
screen_ai / local Screen AI / OCR
```

### Restore mode

Restore mode removes the policies applied by this project in order to return Chrome to its default behavior.

Important: restore scripts only restore Chrome policies applied by this project. They do not restore deleted local files such as `screen_ai` or AI models.

## Usage

### Windows

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-AI-Features.ps1
```

Windows scripts support simulation mode with `-WhatIf`:

```powershell
.\scripts\windows\Disable-Chrome-AI-Features.ps1 -WhatIf
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

After execution, fully close Chrome and relaunch it.

## Verification in Chrome

Open Chrome and go to:

```text
chrome://policy/
```

Click:

```text
Reload policies
```

You should see the hardened mode policies with `OK` status.

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

## screen_ai verification

After applying the script, you can verify that the `screen_ai` folder is no longer present in the Chrome profile.

Main paths:

```text
Windows : %LOCALAPPDATA%\Google\Chrome\User Data\screen_ai
macOS   : ~/Library/Application Support/Google/Chrome/User Data/screen_ai
Linux   : ~/.config/google-chrome/User Data/screen_ai
```

Depending on the Chrome version, nearby paths may also exist. The scripts check several possible paths.

## Reports and backups

Scripts generate reports in:

```text
./reports/
```

Scripts may generate backups in:

```text
./backups/
```

## Limitations

This project greatly reduces browser-side Chrome AI features, but it cannot guarantee complete blocking of all server-side AI-generated content.

For example:

- A web page can display AI-generated content.
- A search engine can display server-side AI results or summaries.
- An installed extension can use its own AI features.
- Google may modify or add policies in future Chrome versions.
- Some policies may depend on the installed Chrome version.
- `screen_ai` may be downloaded again by Chrome if a feature or configuration triggers it.
- The `screen_ai` folder may be present for some users and absent for others depending on Chrome channel, version, flags, staged rollouts, or local usage.

This project does not replace a complete browser privacy configuration.

## Recommended checks

After execution, check:

```text
chrome://policy/
chrome://on-device-internals/
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
Screen AI
OCR
```

## Sources

- Article that motivated the project: https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/
- Chrome Enterprise Policies documentation: https://chromeenterprise.google/policies/
- Chrome Built-in AI documentation: https://developer.chrome.com/docs/ai/

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
Action    : local policies + local model cleanup + screen_ai + reports
```

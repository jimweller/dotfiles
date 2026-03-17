# Open in VS Code

macOS Quick Action (Automator Service) that adds "Open in VS Code" to the Finder right-click context menu.

## Install

```bash
cp -r "Open in VS Code.workflow" ~/Library/Services/
```

## Usage

Right-click any file or folder in Finder → **Quick Actions** → **Open in VS Code**.

Also appears under Finder menu bar → **Services** → **Open in VS Code**.

If the action does not appear, enable it at **System Settings → Privacy & Security → Extensions → Finder Extensions**.

## How it works

Runs a shell script via Automator that calls `open -b com.microsoft.VSCode` on each selected Finder item.

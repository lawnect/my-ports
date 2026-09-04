# My Ports

A lightweight macOS menu bar app for checking local listening TCP ports and killing the owning process.

## Requirements

- macOS 13 or later
- Xcode command line tools with Swift 6 or later

## Development

```sh
make build
make test
make run
```

`make run` launches the app as an accessory app. It does not create a normal window.

### Xcode

Open the direct-distribution macOS app project:

```sh
open MyPorts.xcodeproj
```

Select the `My Ports` scheme and `My Mac`, then use Run or Test normally. The
project keeps App Sandbox disabled because the app needs to inspect and terminate
local processes, and enables Hardened Runtime for Developer ID distribution.

Before creating a distributable archive, select the `My Ports` target, open
Signing & Capabilities, choose your Apple Developer team, and confirm the bundle
identifier. Then choose Product > Archive and, in Organizer, use Distribute App >
Developer ID. Xcode can upload the archive for notarization and export the signed
app.

## App Bundle

```sh
make bundle
open ".build/app/My Ports.app"
```

The bundle uses `LSUIElement=true`, so the app runs without a Dock icon.
The app icon source is `Resources/AppIcon.png`. Re-render it with `make render-icon`, then build `Resources/AppIcon.icns` with `make icons`.

To create a visible distributable copy:

```sh
make dist
```

This writes `dist/My Ports.app`. Remove it after use if you do not want Spotlight to show a duplicate app.

## Install As An App

```sh
make install
open "$HOME/Applications/My Ports.app"
```

After installation, open it from `~/Applications`, Finder, Spotlight, or Launchpad.

For a one-command build, install, and launch:

```sh
make launch
```

## Implementation Notes

- Port discovery uses `lsof` for TCP listeners, parent PIDs, and user IDs, then enriches them with executable paths and bounded ancestry from `ps`.
- The default `Web` filter combines known web ports with recognized server processes.
- Use `Dev` to include classified databases, caches, containers, mobile tools, and development runtimes.
- Process identity takes precedence over a conventional port, and ambiguous matches are labeled in the UI with their classification reason available on hover.
- Executable paths identify compiled Rust, Go, SwiftPM, Node module, and Python virtual-environment processes without retaining full command-line arguments.
- Use `All` to inspect every listening port.
- Process termination uses `/bin/kill -9 <PID>`.
- The UI is an `NSStatusBar` item backed by an `NSPopover` with SwiftUI content.

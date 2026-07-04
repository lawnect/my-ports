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

- Port discovery uses `/usr/sbin/lsof -nP -iTCP -sTCP:LISTEN -F pcPn`.
- The default `Web` filter shows common local web server ports.
- Use `Dev` to include broader development services such as databases and caches.
- Use `All` to inspect every listening port.
- Process termination uses `/bin/kill -9 <PID>`.
- The UI is an `NSStatusBar` item backed by an `NSPopover` with SwiftUI content.

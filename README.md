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

### Service Logos

Service logo SVGs are generated from the
[`@iconify-json/logos`](https://www.npmjs.com/package/@iconify-json/logos)
package, which packages the
[SVG Logos](https://github.com/gilbarbara/logos) collection. The collection is
released under CC0 1.0. The selected SVG assets were exported from
`@iconify-json/logos@1.2.13` and are committed directly to the repository; Node.js
and pnpm are not required to build or run the macOS app.

`caddy.svg`, `elixir.svg`, `rails.svg`, and `rust.svg` remain sourced from
[Simple Icons](https://simpleicons.org/) because the SVG Logos alternatives are
missing or unsuitable at the app's 22-point display size. See
[`ATTRIBUTION.md`](Sources/ShowMeThePorts/Resources/ServiceIcons/ATTRIBUTION.md)
for details. Individual logos remain subject to their owners' trademark and brand
guidelines.

## App Bundle

```sh
make bundle
open ".build/app/My Ports.app"
```

The bundle uses `LSUIElement=true`, so the app runs without a Dock icon.
Both the Xcode project and the `make bundle` path compile
`Resources/AppIcon.icon` with Apple's asset compiler. This places the generated
`AppIcon.icns` and `Assets.car` in the application bundle.

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
- `All` always shows every listening port. The default saved `Dev` filter includes web servers, databases, caches, messaging services, containers, mobile tools, and development runtimes.
- Create and edit saved filters from the `+` button. Filters can combine service categories, process or app names, owner, termination status, local/network exposure, and a port range.
- Filter rules are persisted between launches. Up to two saved filters can be pinned beside `All` for quick access; additional filters remain available in the filter manager.
- Process identity takes precedence over a conventional port, and ambiguous matches are labeled in the UI with their classification reason available on hover.
- Executable paths identify compiled Rust, Go, SwiftPM, Node module, and Python virtual-environment processes without retaining full command-line arguments.
- Bundled application paths and process ancestry distinguish Dia, Serena, Codex, Zed, Figma, Tailscale, VS Code, and Cursor helpers; installed application icons are used when available.
- Process termination uses `/bin/kill -9 <PID>` only for verified processes owned by the current user. Administrator, other-user, macOS, and unknown-owner processes are protected in the UI.
- The UI is an `NSStatusBar` item backed by an `NSPopover` with SwiftUI content.

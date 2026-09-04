APP_NAME := My Ports
OLD_APP_NAME := Show me the ports
BINARY_NAME := ShowMeThePorts
APP_BUNDLE := .build/app/$(APP_NAME).app
DIST_APP_BUNDLE := dist/$(APP_NAME).app
INSTALL_DIR ?= $(HOME)/Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app
OLD_INSTALLED_APP := $(INSTALL_DIR)/$(OLD_APP_NAME).app
OLD_DIST_APP_BUNDLE := dist/$(OLD_APP_NAME).app
ICON_NAME := AppIcon
ICON_SOURCE := Resources/$(ICON_NAME).png
ICON_FILE := Resources/$(ICON_NAME).icns
ICONSET := Resources/$(ICON_NAME).iconset
ICON_RENDERER := Scripts/render_app_icon.swift

.PHONY: build test run render-icon icons bundle dist install launch uninstall clean

build:
	swift build --product $(BINARY_NAME)

test:
	swift test

run:
	swift run $(BINARY_NAME)

render-icon:
	swift "$(ICON_RENDERER)" "$(ICON_SOURCE)"

icons: $(ICON_FILE)

$(ICON_FILE): $(ICON_SOURCE) $(ICON_RENDERER)
	rm -rf "$(ICONSET)"
	mkdir -p "$(ICONSET)"
	sips -z 16 16 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_16x16.png" >/dev/null
	sips -z 32 32 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_16x16@2x.png" >/dev/null
	sips -z 32 32 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_32x32.png" >/dev/null
	sips -z 64 64 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_32x32@2x.png" >/dev/null
	sips -z 128 128 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_128x128.png" >/dev/null
	sips -z 256 256 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_128x128@2x.png" >/dev/null
	sips -z 256 256 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_256x256.png" >/dev/null
	sips -z 512 512 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_256x256@2x.png" >/dev/null
	sips -z 512 512 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_512x512.png" >/dev/null
	sips -z 1024 1024 "$(ICON_SOURCE)" --out "$(ICONSET)/icon_512x512@2x.png" >/dev/null
	iconutil -c icns "$(ICONSET)" -o "$(ICON_FILE)"
	rm -rf "$(ICONSET)"

bundle: $(ICON_FILE)
	swift build -c release --product $(BINARY_NAME)
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$$(swift build -c release --show-bin-path)/$(BINARY_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(BINARY_NAME)"
	cp Resources/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	cp "$(ICON_FILE)" "$(APP_BUNDLE)/Contents/Resources/$(ICON_NAME).icns"
	@if [ -d "$$(swift build -c release --show-bin-path)/ShowMeThePorts_ShowMeThePorts.bundle" ]; then \
		cp -R "$$(swift build -c release --show-bin-path)/ShowMeThePorts_ShowMeThePorts.bundle" "$(APP_BUNDLE)/Contents/Resources/"; \
	fi
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(BINARY_NAME)"

dist: bundle
	rm -rf "$(DIST_APP_BUNDLE)"
	rm -rf "$(OLD_DIST_APP_BUNDLE)"
	mkdir -p dist
	cp -R "$(APP_BUNDLE)" "$(DIST_APP_BUNDLE)"
	@echo "Created: $(DIST_APP_BUNDLE)"

install: bundle
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALLED_APP)"
	rm -rf "$(OLD_INSTALLED_APP)"
	cp -R "$(APP_BUNDLE)" "$(INSTALLED_APP)"
	xattr -dr com.apple.quarantine "$(INSTALLED_APP)" 2>/dev/null || true
	@echo "Installed: $(INSTALLED_APP)"

launch: install
	open "$(INSTALLED_APP)"

uninstall:
	rm -rf "$(INSTALLED_APP)"
	rm -rf "$(OLD_INSTALLED_APP)"

clean:
	rm -rf .build dist

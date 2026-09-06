APP_NAME := PortPig
OLD_APP_NAME := My Ports
LEGACY_APP_NAME := Show me the ports
BINARY_NAME := PortPig
APP_BUNDLE := .build/app/$(APP_NAME).app
DIST_APP_BUNDLE := dist/$(APP_NAME).app
INSTALL_DIR ?= $(HOME)/Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app
OLD_INSTALLED_APP := $(INSTALL_DIR)/$(OLD_APP_NAME).app
LEGACY_INSTALLED_APP := $(INSTALL_DIR)/$(LEGACY_APP_NAME).app
OLD_DIST_APP_BUNDLE := dist/$(OLD_APP_NAME).app
LEGACY_DIST_APP_BUNDLE := dist/$(LEGACY_APP_NAME).app
ICON_NAME := AppIcon
ICON_SOURCE := Resources/$(ICON_NAME).icon
ICON_OUTPUT_DIR := .build/app-icon
ICON_FILE := $(ICON_OUTPUT_DIR)/$(ICON_NAME).icns
ICON_ASSETS := $(ICON_OUTPUT_DIR)/Assets.car
ICON_INFO := $(ICON_OUTPUT_DIR)/Info.plist

.PHONY: build test run icons bundle dist install launch uninstall clean

build:
	swift build --product $(BINARY_NAME)

test:
	swift test

run:
	swift run $(BINARY_NAME)

icons:
	mkdir -p "$(ICON_OUTPUT_DIR)"
	xcrun actool "$(ICON_SOURCE)" \
		--compile "$(ICON_OUTPUT_DIR)" \
		--output-format human-readable-text \
		--notices \
		--warnings \
		--output-partial-info-plist "$(ICON_INFO)" \
		--app-icon "$(ICON_NAME)" \
		--enable-on-demand-resources NO \
		--development-region en \
		--target-device mac \
		--minimum-deployment-target 13.0 \
		--platform macosx

bundle: icons
	swift build -c release --product $(BINARY_NAME)
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$$(swift build -c release --show-bin-path)/$(BINARY_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(BINARY_NAME)"
	cp Resources/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	cp "$(ICON_FILE)" "$(APP_BUNDLE)/Contents/Resources/$(ICON_NAME).icns"
	cp "$(ICON_ASSETS)" "$(APP_BUNDLE)/Contents/Resources/Assets.car"
	cp LICENSE "$(APP_BUNDLE)/Contents/Resources/LICENSE.txt"
	@if [ -d "$$(swift build -c release --show-bin-path)/PortPig_PortPig.bundle" ]; then \
		cp -R "$$(swift build -c release --show-bin-path)/PortPig_PortPig.bundle" "$(APP_BUNDLE)/Contents/Resources/"; \
	fi
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(BINARY_NAME)"
	codesign --force --sign - "$(APP_BUNDLE)"

dist: bundle
	rm -rf "$(DIST_APP_BUNDLE)"
	rm -rf "$(OLD_DIST_APP_BUNDLE)"
	rm -rf "$(LEGACY_DIST_APP_BUNDLE)"
	mkdir -p dist
	cp -R "$(APP_BUNDLE)" "$(DIST_APP_BUNDLE)"
	@echo "Created: $(DIST_APP_BUNDLE)"

install: bundle
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALLED_APP)"
	rm -rf "$(OLD_INSTALLED_APP)"
	rm -rf "$(LEGACY_INSTALLED_APP)"
	cp -R "$(APP_BUNDLE)" "$(INSTALLED_APP)"
	xattr -dr com.apple.quarantine "$(INSTALLED_APP)" 2>/dev/null || true
	@echo "Installed: $(INSTALLED_APP)"

launch: install
	open "$(INSTALLED_APP)"

uninstall:
	rm -rf "$(INSTALLED_APP)"
	rm -rf "$(OLD_INSTALLED_APP)"
	rm -rf "$(LEGACY_INSTALLED_APP)"

clean:
	rm -rf .build dist

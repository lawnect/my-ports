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
VERSION := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
RELEASE_DIR := .build/release
ARCHIVE_PATH := $(RELEASE_DIR)/$(APP_NAME).xcarchive
ARCHIVE_APP := $(ARCHIVE_PATH)/Products/Applications/$(APP_NAME).app
EXPORT_DIR := $(RELEASE_DIR)/export
EXPORTED_APP := $(EXPORT_DIR)/$(APP_NAME).app
EXPORT_OPTIONS := Resources/ExportOptions.plist
RELEASE_ZIP := $(RELEASE_DIR)/$(APP_NAME)-v$(VERSION).zip
DEVELOPER_TEAM_ID ?= K8R5WLB763
NOTARY_PROFILE ?= portpig

.PHONY: build test run icons bundle dist install launch uninstall release-archive release-package release publish clean

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

release-archive: test
	rm -rf "$(ARCHIVE_PATH)"
	mkdir -p "$(RELEASE_DIR)"
	xcodebuild archive \
		-project PortPig.xcodeproj \
		-scheme PortPig \
		-configuration Release \
		-destination "generic/platform=macOS" \
		-archivePath "$(ARCHIVE_PATH)" \
		-allowProvisioningUpdates \
		CODE_SIGN_STYLE=Automatic \
		DEVELOPMENT_TEAM="$(DEVELOPER_TEAM_ID)"
	file "$(ARCHIVE_APP)/Contents/MacOS/$(BINARY_NAME)"
	codesign --verify --deep --strict --verbose=2 "$(ARCHIVE_APP)"
	@test "$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$(ARCHIVE_APP)/Contents/Info.plist")" = "$(VERSION)" || (echo "Xcode and Resources/Info.plist versions do not match."; exit 1)

release-package: release-archive
	rm -rf "$(EXPORT_DIR)"
	xcodebuild -exportArchive \
		-archivePath "$(ARCHIVE_PATH)" \
		-exportPath "$(EXPORT_DIR)" \
		-exportOptionsPlist "$(EXPORT_OPTIONS)" \
		-allowProvisioningUpdates
	file "$(EXPORTED_APP)/Contents/MacOS/$(BINARY_NAME)"
	codesign --verify --deep --strict --verbose=2 "$(EXPORTED_APP)"
	@codesign -dvv "$(EXPORTED_APP)" 2>&1 | rg -q '^Authority=Developer ID Application:' || (echo "The exported app is not signed with Developer ID."; exit 1)
	rm -f "$(RELEASE_ZIP)"
	ditto -c -k --sequesterRsrc --keepParent "$(EXPORTED_APP)" "$(RELEASE_ZIP)"

release: release-package
	xcrun notarytool submit "$(RELEASE_ZIP)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(EXPORTED_APP)"
	xcrun stapler validate "$(EXPORTED_APP)"
	rm -f "$(RELEASE_ZIP)"
	ditto -c -k --sequesterRsrc --keepParent "$(EXPORTED_APP)" "$(RELEASE_ZIP)"
	codesign --verify --deep --strict --verbose=2 "$(EXPORTED_APP)"
	spctl --assess --type execute --verbose=2 "$(EXPORTED_APP)"
	shasum -a 256 "$(RELEASE_ZIP)"

publish: release
	@test -z "$$(git status --porcelain)" || (echo "Commit the working tree before publishing."; exit 1)
	git fetch origin main
	@test "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/main)" || (echo "Push the current commit to origin/main before publishing."; exit 1)
	@test -z "$$(git tag --list "v$(VERSION)")" || (echo "Tag v$(VERSION) already exists."; exit 1)
	gh release create "v$(VERSION)" "$(RELEASE_ZIP)#$(APP_NAME) $(VERSION)" \
		--repo lawnect/portpig \
		--target main \
		--title "$(APP_NAME) $(VERSION)" \
		--generate-notes

clean:
	rm -rf .build dist

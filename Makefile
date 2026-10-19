VERSION := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
APP := build/AFG.app
DMG := build/AFG-v$(VERSION).dmg

SWIFT ?= swift
SWIFT_FLAGS ?= --disable-sandbox --cache-path .build/spm-cache --scratch-path .build
export CLANG_MODULE_CACHE_PATH := $(CURDIR)/.build/clangcache
export SWIFTPM_MODULECACHE_OVERRIDE := $(CURDIR)/.build/modulecache
export TMPDIR := $(CURDIR)/.build/tmp

.PHONY: build app run dmg clean

build:
	mkdir -p .build/tmp .build/clangcache .build/modulecache .build/spm-cache
	$(SWIFT) build -c release --product AFG $(SWIFT_FLAGS)
	$(SWIFT) build -c release --product AFGIconHost $(SWIFT_FLAGS)

app: build
	rm -rf build/AFG.app build/AFG-v*.app
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp .build/release/AFG $(APP)/Contents/MacOS/AFG
	cp .build/release/AFGIconHost $(APP)/Contents/MacOS/AFGIconHost
	codesign --force --sign - $(APP)/Contents/MacOS/AFGIconHost
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	cp Resources/AFG.icns $(APP)/Contents/Resources/AFG.icns
	codesign --force --sign - $(APP)
	@echo "built $(APP)"

run: app
	open $(APP)

dmg: app
	rm -rf build/dmg
	mkdir -p build/dmg
	cp -R $(APP) build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname "AFG" -srcfolder build/dmg -ov -format UDZO $(DMG)
	@echo "built $(DMG)"

clean:
	swift package clean
	rm -rf build

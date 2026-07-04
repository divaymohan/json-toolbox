APP     := JSONToolbox
BINARY  := .build/release/$(APP)
BUNDLE  := $(APP).app

.PHONY: all build app run dev debug clean

all: app

## Build the release binary
build:
	swift build -c release

## Assemble a double-clickable .app bundle around the release binary
app: build
	rm -rf $(BUNDLE)
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	mkdir -p "$(BUNDLE)/Contents/Resources"
	cp Resources/Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp "$(BINARY)" "$(BUNDLE)/Contents/MacOS/$(APP)"
	@echo "Built $(BUNDLE)"

## Build the bundle and launch it
run: app
	open "$(BUNDLE)"

## Fast dev run straight from SwiftPM (no bundle)
dev:
	swift run

## Debug build
debug:
	swift build

clean:
	swift package clean
	rm -rf $(BUNDLE)

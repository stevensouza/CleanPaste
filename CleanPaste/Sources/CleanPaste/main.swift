import Cocoa
import Carbon

// MARK: - Diagnostic Logging

let logFile = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".cleanpaste.log")

func logMsg(_ msg: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(msg)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fh = try? FileHandle(forWritingTo: logFile) {
                fh.seekToEndOfFile()
                fh.write(data)
                fh.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
}

// MARK: - URL Stripping

func stripURLs(from text: String) -> String {
    var result = text

    // Remove parenthesized URLs like (https://...) common in newsletters
    let parenURL = try! NSRegularExpression(
        pattern: #"\s*\(https?://[^\s\)]+\)"#,
        options: []
    )
    result = parenURL.stringByReplacingMatches(
        in: result,
        range: NSRange(result.startIndex..., in: result),
        withTemplate: ""
    )

    // Remove bare URLs (http, https, ftp)
    let bareURL = try! NSRegularExpression(
        pattern: #"https?://[^\s]+"#,
        options: []
    )
    result = bareURL.stringByReplacingMatches(
        in: result,
        range: NSRange(result.startIndex..., in: result),
        withTemplate: ""
    )

    // Clean up any double spaces left behind
    let doubleSpace = try! NSRegularExpression(pattern: #"  +"#, options: [])
    result = doubleSpace.stringByReplacingMatches(
        in: result,
        range: NSRange(result.startIndex..., in: result),
        withTemplate: " "
    )

    return result.trimmingCharacters(in: .whitespaces)
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var isEnabled = true
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Clear old log
        try? "".write(to: logFile, atomically: true, encoding: .utf8)
        logMsg("CleanPaste launched")
        logMsg("AXIsProcessTrusted: \(AXIsProcessTrusted())")
        logMsg("Bundle ID: \(Bundle.main.bundleIdentifier ?? "none")")
        logMsg("Executable: \(Bundle.main.executablePath ?? "unknown")")
        setupMenuBar()
        setupEventTap()
    }

    // MARK: - Menu Bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "CP"
            button.toolTip = "CleanPaste — Cmd+Shift+V to paste without URLs"
        }
        updateMenu()
    }

    func updateMenu() {
        let menu = NSMenu()

        let tapStatus = NSMenuItem(
            title: eventTap != nil ? "Event tap: Active" : "Event tap: FAILED",
            action: nil,
            keyEquivalent: ""
        )
        tapStatus.isEnabled = false
        menu.addItem(tapStatus)

        menu.addItem(NSMenuItem.separator())

        let stateItem = NSMenuItem(
            title: isEnabled ? "CleanPaste: ON" : "CleanPaste: OFF",
            action: nil,
            keyEquivalent: ""
        )
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        let toggleItem = NSMenuItem(
            title: isEnabled ? "Disable" : "Enable",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(
            title: "Test: Copy sample then Cmd+Shift+V",
            action: #selector(runTest),
            keyEquivalent: ""
        )
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit CleanPaste",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    @objc func toggleEnabled() {
        isEnabled.toggle()
        updateMenu()
    }

    @objc func runTest() {
        let sample = "China's Ministry of Education (https://www.chinatalk.media/p/chinas-ai-education-experiment?utm_source=test) released a white paper."
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(sample, forType: .string)

        let alert = NSAlert()
        alert.messageText = "Test clipboard set"
        alert.informativeText = "Clipboard now contains sample text with a URL.\n\nOpen any text editor and press Cmd+Shift+V to paste without the URL.\n\nExpected result:\n\"China's Ministry of Education released a white paper.\""
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - CGEventTap (intercepts Cmd+Shift+V globally)

    func setupEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        logMsg("Creating event tap...")
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logMsg("FAILED to create event tap!")
            let alert = NSAlert()
            alert.messageText = "CleanPaste: Event Tap Failed"
            alert.informativeText = "Could not create the keyboard event tap.\n\nMake sure CleanPaste has Accessibility permission:\nSystem Settings → Privacy & Security → Accessibility"
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Quit")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            } else {
                NSApplication.shared.terminate(nil)
            }
            return
        }

        self.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logMsg("Event tap created and active!")
        updateMenu()
    }
}

// MARK: - Event Tap Callback (C-function pointer)

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Re-enable tap if macOS disabled it due to timeout
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo = userInfo {
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
            if let tap = delegate.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                NSLog("CleanPaste: Re-enabled event tap after timeout")
            }
        }
        return Unmanaged.passUnretained(event)
    }

    guard type == .keyDown, let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()

    guard delegate.isEnabled else {
        return Unmanaged.passUnretained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    // Check for Cmd+Shift+V (keycode 9 = 'v')
    let hasCmd = flags.contains(.maskCommand)
    let hasShift = flags.contains(.maskShift)

    guard keyCode == 9 && hasCmd && hasShift else {
        return Unmanaged.passUnretained(event)
    }

    // It's Cmd+Shift+V — strip URLs from clipboard, then simulate Cmd+V
    logMsg(">>> Intercepted Cmd+Shift+V!")
    let pb = NSPasteboard.general
    guard let originalText = pb.string(forType: .string) else {
        logMsg("No text on clipboard, passing through")
        return Unmanaged.passUnretained(event)
    }

    logMsg("Clipboard text (first 80): \(String(originalText.prefix(80)))")
    let cleanedText = stripURLs(from: originalText)
    logMsg("Cleaned text (first 80): \(String(cleanedText.prefix(80)))")

    // Write cleaned text to clipboard (clearContents removes rich text/HTML too)
    pb.clearContents()
    pb.setString(cleanedText, forType: .string)
    logMsg("Clipboard updated with clean text")

    // Use a PRIVATE event source so physical Shift key state won't bleed into our
    // synthetic Cmd+V. Post at cgSessionEventTap (higher level than HID).
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
        guard let source = CGEventSource(stateID: .privateState) else {
            logMsg("FAILED to create CGEventSource")
            return
        }

        // Post Cmd+V key-down
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            logMsg("FAILED to create keyDown CGEvent")
            return
        }
        keyDown.flags = .maskCommand
        keyDown.post(tap: .cgSessionEventTap)
        logMsg("Posted Cmd+V keyDown")

        // Post Cmd+V key-up after a tiny gap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
                logMsg("FAILED to create keyUp CGEvent")
                return
            }
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgSessionEventTap)
            logMsg("Posted Cmd+V keyUp")
        }

        // Restore original clipboard after paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pb.clearContents()
            pb.setString(originalText, forType: .string)
            logMsg("Clipboard restored to original")
        }
    }

    logMsg("Suppressing original event, returning nil")
    return nil  // suppress the original Cmd+Shift+V
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()

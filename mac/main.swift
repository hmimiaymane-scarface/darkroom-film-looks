// Darkroom for macOS: a small native shell around darkroom.html.
// The page is served from the app bundle through the darkroom:// scheme, which also serves
// photos the user opens via ⌘O, the Dock or "Open With" (only those files, nothing else).
import Cocoa
import WebKit
import UniformTypeIdentifiers

let scheme = "darkroom"

final class SchemeHandler: NSObject, WKURLSchemeHandler {
    private var allowed: [String: URL] = [:]

    /// Registers a user-chosen file and returns the URL the page can fetch it from.
    func register(_ file: URL) -> String {
        let id = UUID().uuidString
        allowed[id] = file
        let name = file.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "photo"
        return "\(scheme)://app/f/\(id)/\(name)"
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        let parts = url.path.split(separator: "/").map(String.init)
        var file: URL?
        if parts.first == "f", parts.count >= 2 {
            file = allowed[parts[1]]
        } else {
            let name = parts.isEmpty ? "darkroom.html" : parts.joined(separator: "/")
            if !name.contains("..") { file = Bundle.main.resourceURL?.appendingPathComponent(name) }
        }
        let mime: String = {
            switch file?.pathExtension.lowercased() {
            case "html": return "text/html; charset=utf-8"
            case "js": return "text/javascript"
            case "css": return "text/css"
            case "jpg", "jpeg": return "image/jpeg"
            case "png": return "image/png"
            default: return "application/octet-stream"
            }
        }()
        DispatchQueue.global(qos: .userInitiated).async {
            let data = file.flatMap { try? Data(contentsOf: $0, options: .mappedIfSafe) }
            DispatchQueue.main.async {
                guard let data else { task.didFailWithError(URLError(.fileDoesNotExist)); return }
                let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": mime, "Content-Length": "\(data.count)"])!
                task.didReceive(resp)
                task.didReceive(data)
                task.didFinish()
            }
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandlerWithReply {
    var window: NSWindow!
    var web: WKWebView!
    let files = SchemeHandler()
    var pageReady = false
    var pending: [URL] = []

    lazy var stateURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Darkroom", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("state.json")
    }()
    var lutsURL: URL { stateURL.deletingLastPathComponent().appendingPathComponent("luts.json") }

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        let cfg = WKWebViewConfiguration()
        cfg.setURLSchemeHandler(files, forURLScheme: scheme)
        cfg.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "darkroom")
        web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = self
        web.navigationDelegate = self
        web.setValue(false, forKey: "drawsBackground")
        if #available(macOS 13.3, *) { web.isInspectable = true }

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1440, height: 900),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Darkroom"
        window.titlebarAppearsTransparent = false
        window.minSize = NSSize(width: 980, height: 620)
        window.backgroundColor = NSColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = web
        window.center()
        window.setFrameAutosaveName("DarkroomMain")
        window.tabbingMode = .disallowed

        web.load(URLRequest(url: URL(string: "\(scheme)://app/darkroom.html")!))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // Finder "Open With", dropping files on the Dock icon
    func application(_ app: NSApplication, open urls: [URL]) { send(urls) }

    func send(_ urls: [URL]) {
        guard pageReady else { pending += urls; return }
        let items: [[String: Any]] = urls.map { u in
            let mod = (try? u.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            return ["url": files.register(u), "name": u.lastPathComponent, "modified": Int(mod.timeIntervalSince1970 * 1000)]
        }
        guard let json = try? JSONSerialization.data(withJSONObject: items),
              let s = String(data: json, encoding: .utf8) else { return }
        web.evaluateJavaScript("addRemote(\(s))")
    }

    // <input type=file> → native open panel
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let p = photoPanel()
        p.allowsMultipleSelection = parameters.allowsMultipleSelection
        p.beginSheetModal(for: window) { r in completionHandler(r == .OK ? p.urls : nil) }
    }

    // Keep the app page in place (a stray drop or link must not navigate away).
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(action.request.url?.scheme == scheme ? .allow : .cancel)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        pageReady = false
        webView.reload()
    }

    // JS bridge
    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard let b = message.body as? [String: Any], let cmd = b["cmd"] as? String else {
            replyHandler(nil, "bad message"); return
        }
        switch cmd {
        case "ready":
            pageReady = true
            let q = pending; pending = []
            if !q.isEmpty { send(q) }
            replyHandler(true, nil)
        case "loadState":
            replyHandler(try? String(contentsOf: stateURL, encoding: .utf8), nil)
        case "saveState":
            if let s = b["data"] as? String { try? s.write(to: stateURL, atomically: true, encoding: .utf8) }
            replyHandler(true, nil)
        case "loadLuts":
            replyHandler(try? String(contentsOf: lutsURL, encoding: .utf8), nil)
        case "saveLuts":
            if let s = b["data"] as? String { try? s.write(to: lutsURL, atomically: true, encoding: .utf8) }
            replyHandler(true, nil)
        case "pickFolder":
            let p = NSOpenPanel()
            p.canChooseDirectories = true
            p.canChooseFiles = false
            p.canCreateDirectories = true
            p.prompt = "Export Here"
            p.message = (b["message"] as? String) ?? "Choose where to save your edited photos"
            if let last = UserDefaults.standard.string(forKey: "exportDir") { p.directoryURL = URL(fileURLWithPath: last) }
            p.beginSheetModal(for: window) { r in
                if r == .OK, let u = p.url { UserDefaults.standard.set(u.path, forKey: "exportDir") }
                replyHandler(r == .OK ? p.url?.path : nil, nil)
            }
        case "save":
            guard let dir = b["dir"] as? String, let name = b["name"] as? String,
                  let d64 = b["data"] as? String, let data = Data(base64Encoded: d64) else {
                replyHandler(nil, "bad save request"); return
            }
            let folder = URL(fileURLWithPath: dir)
            let safe = (name as NSString).lastPathComponent
            var url = folder.appendingPathComponent(safe)
            let base = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            var i = 2
            while FileManager.default.fileExists(atPath: url.path) {
                url = folder.appendingPathComponent("\(base)-\(i).\(ext)"); i += 1
            }
            do { try data.write(to: url); replyHandler(url.lastPathComponent, nil) }
            catch { replyHandler(nil, error.localizedDescription) }
        case "reveal":
            if let dir = b["dir"] as? String { NSWorkspace.shared.open(URL(fileURLWithPath: dir)) }
            replyHandler(true, nil)
        default:
            replyHandler(nil, "unknown command")
        }
    }

    func photoPanel() -> NSOpenPanel {
        let p = NSOpenPanel()
        p.canChooseDirectories = false
        p.canChooseFiles = true
        p.message = "Choose photos (JPG, PNG, Canon CR2), LUTs (.cube) or looks (.darkroom)"
        var types: [UTType] = [.jpeg, .png, .webP]
        if let cr2 = UTType("com.canon.cr2-raw-image") { types.append(cr2) }
        if let cube = UTType(filenameExtension: "cube") { types.append(cube) }
        if let look = UTType(filenameExtension: "darkroom") { types.append(look) }
        p.allowedContentTypes = types
        return p
    }

    @objc func addPhotos(_ sender: Any?) {
        let p = photoPanel()
        p.allowsMultipleSelection = true
        p.beginSheetModal(for: window) { [weak self] r in
            if r == .OK { self?.send(p.urls) }
        }
    }

    @objc func exportPhotos(_ sender: Any?) { web.evaluateJavaScript("openExport()") }
    @objc func undo(_ sender: Any?) { web.evaluateJavaScript("undo()") }
    @objc func redo(_ sender: Any?) { web.evaluateJavaScript("redo()") }
    @objc func showHelp(_ sender: Any?) { web.evaluateJavaScript("document.getElementById('helpDlg').showModal()") }

    func buildMenu() {
        let main = NSMenu()
        func menu(_ title: String, _ items: [NSMenuItem]) {
            let item = NSMenuItem(); let m = NSMenu(title: title)
            items.forEach(m.addItem); item.submenu = m; main.addItem(item)
        }
        func item(_ t: String, _ a: Selector?, _ k: String = "", _ mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
            let i = NSMenuItem(title: t, action: a, keyEquivalent: k); i.keyEquivalentModifierMask = mods; return i
        }
        menu("Darkroom", [
            item("About Darkroom", #selector(NSApplication.orderFrontStandardAboutPanel(_:))),
            .separator(),
            item("Hide Darkroom", #selector(NSApplication.hide(_:)), "h"),
            item("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option]),
            .separator(),
            item("Quit Darkroom", #selector(NSApplication.terminate(_:)), "q"),
        ])
        menu("File", [
            item("Add Photos…", #selector(addPhotos(_:)), "o"),
            item("Export…", #selector(exportPhotos(_:)), "e"),
            .separator(),
            item("Close Window", #selector(NSWindow.performClose(_:)), "w"),
        ])
        menu("Edit", [
            item("Undo", #selector(undo(_:)), "z"),
            item("Redo", #selector(redo(_:)), "z", [.command, .shift]),
        ])
        menu("View", [
            item("Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control]),
        ])
        menu("Window", [
            item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"),
            item("Zoom", #selector(NSWindow.performZoom(_:))),
        ])
        menu("Help", [item("Keyboard Shortcuts", #selector(showHelp(_:)), "/")])
        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

// Draws the 1024×1024 app icon: usage `swift mac/icon.swift out.png`
import AppKit
let size = 1024.0
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
// macOS icon grid: 824pt rounded square centred on a 1024 canvas
let r = CGRect(x: 100, y: 100, width: 824, height: 824)
let bg = NSBezierPath(roundedRect: r, xRadius: 185, yRadius: 185)
NSGradient(colors: [NSColor(calibratedRed: 0.17, green: 0.16, blue: 0.17, alpha: 1),
                    NSColor(calibratedRed: 0.06, green: 0.06, blue: 0.07, alpha: 1)])!.draw(in: bg, angle: -90)
// lens rings
let c = CGPoint(x: 512, y: 512)
func circle(_ rad: CGFloat) -> NSBezierPath { NSBezierPath(ovalIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)) }
NSColor(calibratedWhite: 0.02, alpha: 1).setFill(); circle(300).fill()
NSColor(calibratedWhite: 0.28, alpha: 1).setStroke(); let ring = circle(300); ring.lineWidth = 14; ring.stroke()
// warm film-glow core
let glow = NSGradient(colors: [NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.55, alpha: 1),
                               NSColor(calibratedRed: 0.94, green: 0.55, blue: 0.20, alpha: 1),
                               NSColor(calibratedRed: 0.55, green: 0.18, blue: 0.10, alpha: 1),
                               NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.06, alpha: 0)])!
glow.draw(in: circle(250), relativeCenterPosition: NSPoint(x: -0.25, y: 0.25))
// aperture blades hint
ctx.setStrokeColor(NSColor(calibratedWhite: 0, alpha: 0.35).cgColor); ctx.setLineWidth(10)
for i in 0..<6 {
    let a = Double(i) * .pi / 3
    ctx.move(to: CGPoint(x: c.x + cos(a) * 90, y: c.y + sin(a) * 90))
    ctx.addLine(to: CGPoint(x: c.x + cos(a + 1.1) * 250, y: c.y + sin(a + 1.1) * 250))
}
ctx.strokePath()
NSColor(calibratedWhite: 1, alpha: 0.85).setFill(); circle(28).fill()
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

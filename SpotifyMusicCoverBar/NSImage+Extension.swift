import AppKit

extension NSImage {
    func resizedForMenuBar(size: CGFloat = 18, cornerRadius: CGFloat = 3) -> NSImage {
        let newSize = NSSize(width: size, height: size)
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: newSize)
        let clipPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        clipPath.addClip()
        
        self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        
        newImage.isTemplate = false
        return newImage
    }
}

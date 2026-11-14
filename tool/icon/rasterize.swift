// Renders an SVG into PNG files (with or without alpha) or a multi-size Windows
// .ico, using AppKit's built-in SVG support. Used by generate_icons.sh.
//
//   swiftc -O -o rasterize rasterize.swift
//   ./rasterize png        in.svg out.png 512
//   ./rasterize png-opaque in.svg out.png 1024      # no alpha channel (iOS)
//   ./rasterize ico        in.svg out.ico           # 16,24,32,48,64,128,256
import AppKit

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("rasterize: \(message)\n".utf8))
    exit(1)
}

/// Rasterizes the SVG at `path` into a square RGBA bitmap of `size` points.
func render(_ path: String, size: Int) -> NSBitmapImageRep {
    guard let image = NSImage(contentsOfFile: path) else { fail("cannot read \(path)") }
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: size * 4, bitsPerPixel: 32)
    else { fail("cannot allocate \(size)x\(size) bitmap") }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { fail("cannot make context") }
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
               from: .zero, operation: .sourceOver, fraction: 1.0)
    return rep
}

/// Drops the alpha channel, compositing over white. Graphics contexts only back
/// RGBA bitmaps, so alpha-free output has to be copied across afterwards.
func flattened(_ rep: NSBitmapImageRep, size: Int) -> NSBitmapImageRep {
    guard let source = rep.bitmapData else { fail("no bitmap data") }
    guard let out = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: size * 3, bitsPerPixel: 24),
        let target = out.bitmapData
    else { fail("cannot allocate opaque bitmap") }
    out.size = NSSize(width: size, height: size)

    for y in 0..<size {
        for x in 0..<size {
            let src = y * rep.bytesPerRow + x * 4, dst = y * out.bytesPerRow + x * 3
            let alpha = Int(source[src + 3])
            for channel in 0..<3 {  // premultiplied source over white
                target[dst + channel] = UInt8((Int(source[src + channel]) * 255 + (255 - alpha) * 255) / 255)
            }
        }
    }
    return out
}

func pngData(_ rep: NSBitmapImageRep) -> Data {
    guard let data = rep.representation(using: .png, properties: [:]) else { fail("PNG encode failed") }
    return data
}

/// A 32-bit BGRA DIB (BITMAPINFOHEADER + bottom-up pixels + empty AND mask),
/// which is what .ico entries hold for the smaller sizes.
func dibData(_ rep: NSBitmapImageRep, size: Int) -> Data {
    guard let pixels = rep.bitmapData else { fail("no bitmap data") }
    let spp = rep.samplesPerPixel, rowBytes = rep.bytesPerRow
    var out = Data()
    func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
    func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
    u32(40); u32(UInt32(size)); u32(UInt32(size * 2)); u16(1); u16(32)
    u32(0); u32(UInt32(size * size * 4)); u32(2835); u32(2835); u32(0); u32(0)
    for y in stride(from: size - 1, through: 0, by: -1) {
        for x in 0..<size {
            let p = y * rowBytes + x * spp
            let a: UInt8 = spp == 4 ? pixels[p + 3] : 255
            out.append(contentsOf: [pixels[p + 2], pixels[p + 1], pixels[p], a])  // BGRA
        }
    }
    out.append(Data(count: ((size + 31) / 32) * 4 * size))  // AND mask, all opaque
    return out
}

func writeICO(_ svg: String, to path: String) {
    let dibSizes = [16, 24, 32, 48, 64], pngSizes = [128, 256]
    let images: [(size: Int, data: Data)] =
        dibSizes.map { ($0, dibData(render(svg, size: $0), size: $0)) } +
        pngSizes.map { ($0, pngData(render(svg, size: $0))) }

    var out = Data()
    func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
    func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
    u16(0); u16(1); u16(UInt16(images.count))
    var offset = 6 + 16 * images.count
    for image in images {
        let dim = UInt8(image.size == 256 ? 0 : image.size)
        out.append(contentsOf: [dim, dim, 0, 0]); u16(1); u16(32)
        u32(UInt32(image.data.count)); u32(UInt32(offset))
        offset += image.data.count
    }
    for image in images { out.append(image.data) }
    do { try out.write(to: URL(fileURLWithPath: path)) } catch { fail("\(error)") }
}

let args = CommandLine.arguments
guard args.count >= 4 else { fail("usage: rasterize <png|png-opaque|ico> <in.svg> <out> [size]") }
let mode = args[1], input = args[2], output = args[3]

switch mode {
case "ico":
    writeICO(input, to: output)
case "png", "png-opaque":
    guard args.count >= 5, let size = Int(args[4]), size > 0 else { fail("missing or bad size") }
    var rep = render(input, size: size)
    if mode == "png-opaque" { rep = flattened(rep, size: size) }
    do { try pngData(rep).write(to: URL(fileURLWithPath: output)) }
    catch { fail("\(error)") }
default:
    fail("unknown mode \(mode)")
}

public struct Color: Equatable {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8

    static let black = Color(r: 0, g: 0, b: 0)

	init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = .max) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    func with(brightness: Double) -> Color {
        return Color(
            r: UInt8(Double(r) * brightness),
            g: UInt8(Double(g) * brightness),
            b: UInt8(Double(b) * brightness)
        )
    }
}

public struct Bitmap {
    private(set) var pixels: [Color]
    public let width, height: Int

    subscript(x: Int, y: Int) -> Color {
        get { pixels[pixels.startIndex + x * height + y] }
        set { pixels[pixels.startIndex + x * height + y] = newValue }
    }

    subscript(v: Vector) -> Color {
		self[
			Int(v.x * Double(width)).wrapped(to: width),
			Int(v.y * Double(height)).wrapped(to: height)
		]
    }

    init(height: Int, pixels: [Color]) {
        self.height = height
        self.pixels = pixels
        width = pixels.count / height
    }

    init(width: Int, height: Int, color: Color) {
        self.width = width
        self.height = height
        pixels = Array(repeating: color, count: width * height)
    }
}

private extension Int {
    func wrapped(to modulo: Int) -> Int {
        let temp = self % modulo
        return temp < 0 ? temp + modulo : temp
    }
}

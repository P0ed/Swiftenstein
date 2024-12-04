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

	mutating func add(_ color: Color) {
		a += min(color.a, .max - a)
		r += min(color.r, .max - r)
		g += min(color.g, .max - g)
		b += min(color.b, .max - b)
	}
}

public struct Bitmap {
    private(set) var pixels: [Color]
    public let width, height: Int

    subscript(x: Int, y: Int) -> Color {
        get { pixels[x * height + y] }
        set { pixels[x * height + y] = newValue }
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

	mutating func modify(_ f: (Int, Int, inout Color) -> Void) {
		for x in 0..<width {
			for y in 0..<height {
				f(x, y, &self[x, y])
			}
		}
	}
}

private extension Int {
    func wrapped(to modulo: Int) -> Int {
        let temp = self % modulo
        return temp < 0 ? temp + modulo : temp
    }
}

import Cocoa
import SpriteKit
import GameplayKit
import GameController

let simulationStep = 1.0 / 120
let maxFPS = 60.0

struct Controls {
	var v = CGPoint.zero
	var rot = 0 as CGFloat
	var firing = false
	var action = false
	var nextBong = false
	var prevBong = false
}

final class ViewController: NSViewController {
	private let imageView = NSImageView()
	private let overlay = NSView()
	private var lifetime: [Any?] = []

	var world: World!
	var timer: Timer?
	var simulationTime: TimeInterval = 0
	var runningTime: TimeInterval = 0
	var levelComplete = false
	var gameOver = false
	var controls = Controls()

	override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(imageView)
		imageView.frame = view.bounds
		imageView.imageScaling = .scaleProportionallyUpOrDown
		imageView.wantsLayer = true
		imageView.layer?.magnificationFilter = .nearest

		view.addSubview(overlay)
		overlay.frame = view.bounds
		overlay.wantsLayer = true

		resetGame()

		var lastFrameTime = CFAbsoluteTimeGetCurrent()
		timer = Timer.scheduledTimer(withTimeInterval: 1.0 / maxFPS, repeats: true) { _ in
			let dt = CFAbsoluteTimeGetCurrent() - lastFrameTime
			lastFrameTime += dt
			self.runningTime += min(1, dt)
			self.update()
		}

		lifetime = [
			NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] e in
				guard let self else { return e }
				let isDown = e.type == .keyDown
				switch e.keyCode {
				case 0x31:
					controls.firing = isDown
				case 124:
					if e.modifierFlags.contains(.shift) {
						controls.v.x = isDown ? 1 : 0
						controls.rot = 0
					} else {
						controls.rot = isDown ? 1 : 0
						controls.v.x = 0
					}
				case 123:
					if e.modifierFlags.contains(.shift) {
						controls.v.x = isDown ? -1 : 0
						controls.rot = 0
					} else {
						controls.rot = isDown ? -1 : 0
						controls.v.x = 0
					}
				case 126: controls.v.y = isDown ? 1 : 0
				case 125: controls.v.y = isDown ? -1 : 0
				default: return e
				}
				return nil
			},
			NotificationCenter.default.addObserver(
				forName: .GCControllerDidBecomeCurrent,
				object: nil,
				queue: .main,
				using: { [weak self] n in
					guard let gamepad = (n.object as? GCController)?.extendedGamepad else { return }

					gamepad.leftThumbstick.valueChangedHandler = { _, x, y in
						self?.controls.v = CGPoint(x: CGFloat(x), y: CGFloat(y) * 1.4)
					}
					gamepad.rightThumbstick.valueChangedHandler = { _, x, y in
						self?.controls.rot = CGFloat(x)
					}
					gamepad.leftTrigger.pressedChangedHandler = { _, _, pressed in
						self?.controls.action = pressed
					}
					gamepad.rightTrigger.pressedChangedHandler = { _, _, pressed in
						self?.controls.firing = pressed
					}
					gamepad.leftShoulder.pressedChangedHandler = { _, _, pressed in
						self?.controls.prevBong = pressed
					}
					gamepad.rightShoulder.pressedChangedHandler = { _, _, pressed in
						self?.controls.nextBong = pressed
					}
				}
			)
		]
	}

	override func viewDidLayout() {
		super.viewDidLayout()
		overlay.frame = view.bounds
		overlay.layer?.frame = view.bounds
		imageView.frame = view.bounds
	}

	func update() {
		while simulationTime < runningTime {
			simulationTime += simulationStep

			if gameOver, controls.firing {
				resetGame()
				return
			}

			world.player.rotate(controls.rot * turnSpeed * simulationStep)

			if !world.player.isDead, !levelComplete {
				world.player.advance(controls.v.y * walkSpeed * simulationStep)
				world.player.strafe(controls.v.x * walkSpeed * simulationStep)

				if controls.firing { world.player.fire() }
				if controls.prevBong { world.player.prevBong(); controls.prevBong = false }
				if controls.nextBong { world.player.nextBong(); controls.nextBong = false }
			}

			world.update(dt: simulationStep)
			let hp = String(format: "%2f", world.player.health)
			let ammo = world.player.weaponType?.ammoType.flatMap { world.player.ammo[$0] } ?? 0
			view.window?.title = "hp: \(hp)\t\t\t\tammo: \(ammo)"
		}

		let aspect = Double(imageView.bounds.width / imageView.bounds.height)
		let viewport = aspect > 1 ?
			Vector(resolution * aspect, resolution) :
			Vector(resolution, resolution / aspect)

		imageView.image = NSImage(bitmap: world.render(
			pos: world.player.position,
			dir: world.player.direction,
			viewport: viewport,
			eyeline: world.player.eyeline
		))
	}

	func resetGame() {
		overlay.alphaValue = 0

		gameOver = false
		levelComplete = false
		world = makeWorld(delegate: self)

		runningTime = 0
		simulationTime = 0
	}
}

extension ViewController: PlayerDelegate {

	func playerPoweredUp(_: Player) {
		blink(color: .green)
	}

	func playerWasHurt(_: Player) {
		blink(color: .red)
	}

	func playerWasKilled(_: Player) {
		if levelComplete { return }
        
		blink(color: .red) {
			self.blink(color: .red, from: 0, to: 1, duration: 2) {
				self.gameOver = true
			}
		}
	}

	func playerDidEndLevel(_: Player) {
		levelComplete = true
		blink(color: .white) {
			self.blink(color: .white, from: 0, to: 1, duration: 2) {
				self.gameOver = true
				self.levelComplete = true
			}
		}
	}

	private func blink(color: NSColor,  from: TimeInterval = 0.5, to: TimeInterval = 0, duration: TimeInterval = 0.5, completion: @escaping () -> Void = {}) {
		overlay.alphaValue = from
		overlay.layer?.backgroundColor = color.cgColor
		NSAnimationContext.runAnimationGroup { ctx in
			ctx.duration = duration
			ctx.allowsImplicitAnimation = true
			self.overlay.animator().alphaValue = to
		} completionHandler: {
			completion()
		}
	}
}

import SpriteKit
import GameplayKit

final class GameScene: SKScene {
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?

	override func sceneDidLoad() {
		
	}

    override func didMove(to view: SKView) {
        
        label = self.childNode(withName: "helloLabel") as? SKLabelNode
        if let label {
            label.alpha = 0.0
            label.run(.fadeIn(withDuration: 2.0))
        }

        let w = (size.width + size.height) * 0.05
        spinnyNode = SKShapeNode(rectOf: CGSize(width: w, height: w), cornerRadius: w * 0.3)
        if let spinnyNode {
            spinnyNode.lineWidth = 2.5

            spinnyNode.run(.repeatForever(.rotate(byAngle: Double.pi, duration: 1)))
            spinnyNode.run(.sequence([
				.wait(forDuration: 0.5),
                .fadeOut(withDuration: 0.5),
                .removeFromParent()
			]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31: label?.run(.pulse, withKey: "fadeInOut") // 0x31 == " "
        default: break
        }
    }
    
	override func update(_ currentTime: TimeInterval) {}
}

extension SKAction {

	static var pulse: SKAction { SKAction(named: "Pulse")! }
}

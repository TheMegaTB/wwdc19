//
//  GameEndedScene.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

public enum DeathReason {
    case crushedToBits(acceleration: CGFloat)
    case evaporated
    case strandedInOrbit
}

public enum GameEndState {
    case landed(score: Int)
    case died(reason: DeathReason)
}

public class GameEndedScene: SKScene {
    let gameEndState: GameEndState
    let titleNode = SKLabelNode()
    let subtitleNode = SKLabelNode()
    var newGameButton: ButtonNode!

    public init(size: CGSize, gameEndState: GameEndState) {
        self.gameEndState = gameEndState
        super.init(size: size)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMove(to view: SKView) {
        titleNode.fontSize = 80
        titleNode.position = CGPoint(x: 0, y: 250)

        subtitleNode.fontSize = 45
        subtitleNode.position = CGPoint(x: 0, y: 150)

        addChild(titleNode)
        addChild(subtitleNode)

        newGameButton = ButtonNode(text: "Restart") { _ in
            let targetScene = GameScene(size: self.size)
            targetScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 2)
            transition.pausesOutgoingScene = false
            transition.pausesIncomingScene = false
            self.scene!.view!.presentScene(targetScene, transition: transition)
        }
        newGameButton.position = CGPoint(x: 0, y: 50)
        addChild(newGameButton)

        switch gameEndState {
        case .landed(let score):
            touchdownConfirmed(score)
        case .died(let reason):
            titleNode.text = "Dang it!"
            switch reason {
            case .evaporated:
                evaporated()
            case .strandedInOrbit:
                strandedInOrbit()
            case .crushedToBits(let acceleration):
                crushedToBits(acceleration)
            }
        }
    }

    var viewport: CGRect {
        let frameOriginInScene = convertPoint(fromView: frame.origin)
        return CGRect(
            origin: CGPoint(x: frameOriginInScene.x / 2, y: -frameOriginInScene.y / 2),
            size: frame.size
        )
    }

    func evaporated() {
        subtitleNode.text = "You have been evaporated!"

        let fire = SKEmitterNode(fileNamed: Emitter.menu)!
        fire.zRotation = 0.95
        fire.position = CGPoint(x: 0, y: -400)
        addChild(fire)

        addStars()
    }

    func strandedInOrbit() {
        subtitleNode.text = "You are stranded in orbit!"
        centerText()
        addStars()
    }

    func crushedToBits(_ acceleration: CGFloat) {
        subtitleNode.text = String(format: "You were crushed by %.2fG", acceleration / Planet.gravitationalAcc)
        addGround()
        let capsule = addCapsule()
        capsule.physicsBody?.velocity = CGVector(dx: 0, dy: -acceleration * 10)
    }

    func touchdownConfirmed(_ score: Int) {
        titleNode.text = "Touchdown confirmed!"
        subtitleNode.text = "Score: \(score)"

        addCapsule()
        addGround()
    }

    func addStars() {
        let stars = SKEmitterNode(fileNamed: Emitter.stars)!
        addChild(stars)
    }

    func centerText() {
        titleNode.position = CGPoint(x: 0, y: 50)
        subtitleNode.position = CGPoint(x: 0, y: -50)
        newGameButton.position = CGPoint(x: 0, y: -150)
    }

    @discardableResult
    func addCapsule() -> CapsuleNode {
        let viewport = self.viewport

        let capsule = CapsuleNode()
        capsule.position = CGPoint(x: 0, y: viewport.origin.y + viewport.height + 150)
        capsule.physicsBody?.mass = Capsule.mass
        capsule.physicsBody?.angularVelocity = 0.25
        capsule.physicsBody?.restitution = 0.3
        addChild(capsule)

        return capsule
    }

    func addGround() {
        let viewport = self.viewport

        let segments = 5
        let amplitude = 50
        let defaultY = viewport.origin.y + CGFloat(amplitude)
        let segmentWidth = viewport.size.width / CGFloat(segments)
        var groundPoints: [CGPoint] = [viewport.origin]
        for i in 0...segments {
            let x = viewport.origin.x + segmentWidth * CGFloat(i)
            let dY = CGFloat(arc4random_uniform(UInt32(amplitude))) - CGFloat(amplitude / 2)
            var y = defaultY + dY
            if i == 0 || i == segments {
                y += 150
            }
            groundPoints.append(CGPoint(x: x, y: y))
        }
        groundPoints.append(CGPoint(x: viewport.origin.x + viewport.size.width, y: viewport.origin.y))

        let ground = SKShapeNode(splinePoints: &groundPoints, count: groundPoints.count)
        ground.strokeColor = SKColor.yellow
        ground.fillColor = ground.strokeColor
        ground.physicsBody = SKPhysicsBody(edgeChainFrom: ground.path!)
        ground.physicsBody?.isDynamic = false
        addChild(ground)
    }
}

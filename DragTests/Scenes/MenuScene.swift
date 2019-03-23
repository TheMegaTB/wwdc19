//
//  MenuScene.swift
//  DragTests
//
//  Created by Til Blechschmidt on 23.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.physicsWorld.gravity = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        let gameTitle = SKLabelNode(text: "REENTRY")
        gameTitle.fontSize = 100
        gameTitle.position = CGPoint(x: 0, y: 250)
        addChild(gameTitle)

        let startButton = ButtonNode(text: "Launch", scale: 2) { _ in
            let targetScene = GameScene(size: self.size)
            targetScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 2)
            transition.pausesOutgoingScene = false
            transition.pausesIncomingScene = false
            self.scene!.view!.presentScene(targetScene, transition: transition)
        }
        startButton.position = CGPoint(x: 0, y: -350)
        addChild(startButton)

        let shake = SKAction.repeatForever(SKAction.shake(duration: 100, amplitudeX: 15, amplitudeY: 10))

        let capsuleWrapper = SKNode()
        capsuleWrapper.position = CGPoint(x: 1000, y: 1000)

        let flyInPositions: [(CGPoint, TimeInterval)] = [
            (CGPoint(x: -250, y: -300), 1.0),
            (CGPoint(x: 0, y: -50), 1.0),
            (CGPoint(x: -150, y: -200), 1.0)
        ]

        var flyInActions = flyInPositions.map { (position: (CGPoint, TimeInterval)) -> SKAction in
            let action = SKAction.move(to: position.0, duration: position.1)
            action.timingMode = .easeInEaseOut
            return action
        }

        flyInActions.append(
            SKAction.repeatForever(
                SKAction.sequence([
                    flyInActions[flyInActions.count - 2],
                    flyInActions.last!
                ])
            )
        )

        capsuleWrapper.run(SKAction.sequence(flyInActions))
        addChild(capsuleWrapper)

        let particles = SKEmitterNode(fileNamed: Emitter.menu)!
        particles.run(shake)
        capsuleWrapper.addChild(particles)

        let capsule = CapsuleNode()
        capsule.position = CGPoint(x: 0, y: -10)
        capsule.setScale(0.3)
        capsule.zPosition = Layer.entity
        capsule.zRotation = -0.9
        capsule.alpha = 0.7
        capsule.run(shake)
        capsuleWrapper.addChild(capsule)
    }
}

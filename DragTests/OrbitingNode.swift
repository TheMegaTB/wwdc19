//
//  OrbitingNode.swift
//  DragTests
//
//  Created by Til Blechschmidt on 18.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class OrbitingNode: SKShapeNode {
    var onRails: Bool = false {
        didSet {
            physicsBody?.allowsRotation = !onRails
            physicsBody?.collisionBitMask = onRails ? 0 : 0xFFFFFFFF

            if !oldValue {
                updateOrbit()
            } else {
                // TODO Update orbitalLine
            }
        }
    }

    var orbitalParameters: OrbitalParameters!
    private(set) var orbitalLine: SKShapeNode

    private var localTime: TimeInterval = 0
    private let reference: SKNode

    private var previousVelocity: CGVector? = nil
    private var previousPosition: CGPoint? = nil

    private let gravitationalConstant: Double = 1.0

    init(reference planet: SKNode) {
        orbitalLine = SKShapeNode()
        orbitalLine.strokeColor = SKColor.red.withAlphaComponent(0.5)
        orbitalLine.lineWidth = 0.5

        reference = planet

        let size = CGSize(width: 10, height: 10)
        let rect = CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size)

        super.init()
        path = CGPath(roundedRect: rect, cornerWidth: 2, cornerHeight: 2, transform: nil)

        strokeColor = SKColor.purple
        fillColor = SKColor.purple

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.mass = 0.5
        physicsBody?.linearDamping = 0
        physicsBody?.angularDamping = 0
        physicsBody?.velocity = CGVector(dx: 0, dy: 100)
        physicsBody?.isDynamic = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(deltaTime: TimeInterval) {
        let dT = deltaTime * Double(speed)
        localTime += dT

        if onRails {
            let (position, speed) = orbitalParameters.cartesianState(after: localTime)

            self.position = CGPoint(x: position.x + Double(reference.position.x), y: position.y + Double(reference.position.y))
            self.physicsBody?.velocity = CGVector(dx: speed.x, dy: speed.y)

            previousVelocity = self.physicsBody?.velocity
            previousPosition = self.position
        } else {
            // Update the orbital parameters in order for the orbitalLine to get updated
            updateOrbit()

            let G: CGFloat = CGFloat(gravitationalConstant)
            guard let m1 = physicsBody?.mass, let m2 = reference.physicsBody?.mass else { return }
            let npVec = Vector(position) - Vector(reference.position)
            let npVecNorm = npVec.normalized()
            let r = CGFloat(npVec.length)
            let F = G * m1 * m2 / pow(r, 2)
            let FVec = CGVector(dx: -F * CGFloat(npVecNorm.x), dy: -F * CGFloat(npVecNorm.y))
            self.physicsBody?.applyForce(FVec)
        }
    }

    func updateOrbit() {
        let planetPosition = Vector(Double(reference.position.x), Double(reference.position.y), 0)
        let entityPosition = Vector(Double(position.x), Double(position.y), 0)

        let G = gravitationalConstant // 6.674 * pow(10.0, -11.0)
        let mu = G * Double(reference.physicsBody!.mass)
        let eci = entityPosition - planetPosition
        let velocity = Vector(physicsBody!.velocity)

        localTime = 0
        orbitalParameters = OrbitalParameters(positionVector: eci, velocityVector: velocity, gravitationalConstant: mu)
        orbitalLine.path = orbitalParameters.orbitPath()
    }
}

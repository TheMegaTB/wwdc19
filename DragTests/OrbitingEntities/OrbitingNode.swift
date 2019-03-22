//
//  OrbitingNode.swift
//  DragTests
//
//  Created by Til Blechschmidt on 18.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class OrbitingNode: SKShapeNode {
    var onRails: Bool = true {
        didSet {
            physicsBody?.allowsRotation = !onRails
            physicsBody?.collisionBitMask = onRails ? 0 : 0xFFFFFFFF

            if !oldValue {
                updateOrbit()
            }
        }
    }

    var displayState: DisplayState {
        didSet {
            redrawOrbit()
            redrawPosition()
        }
    }

    var heightAboveTerrain: CGFloat {
        return (Vector(position) - Vector(reference.position)).length - reference.bodyRadius
    }

    var apoapsisHeight: CGFloat {
        return orbitalParameters.apoapsisHeight - reference.bodyRadius
    }

    var periapsisHeight: CGFloat {
        return orbitalParameters.periapsisHeight - reference.bodyRadius
    }

    var orbitalParameters: OrbitalParameters!
    private(set) var orbitalLine: SKShapeNode
    private(set) var periapsisMarker: OrbitMarker = OrbitMarker(label: "Periapsis")
    private(set) var apoapsisMarker: OrbitMarker = OrbitMarker(label: "Apoapsis")
    private(set) var positionMarker: SKShapeNode = SKShapeNode(circleOfRadius: 20.0)

    private var localTime: TimeInterval = 0
    private let reference: PlanetNode

    private let gravitationalConstant: CGFloat = 6.674 * pow(10.0, -11.0)

    init(reference: PlanetNode, displayState: DisplayState) {
        orbitalLine = SKShapeNode()
        orbitalLine.strokeColor = SKColor.red.withAlphaComponent(0.5)
        orbitalLine.lineWidth = 0.5

        self.reference = reference

        self.displayState = displayState

        let size = CGSize(width: 72, height: 108)
        let rect = CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size)

        super.init()
        path = CGPath(roundedRect: rect, cornerWidth: 2, cornerHeight: 2, transform: nil)

        strokeColor = SKColor.purple
        fillColor = SKColor.purple

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.mass = 6400 // 419725 // Roughly the ISS weight
        physicsBody?.linearDamping = 0
        physicsBody?.angularDamping = 0
        physicsBody?.velocity = CGVector(dx: 0, dy: 7666) // ISS Orbital speed
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = !onRails
        physicsBody?.collisionBitMask = onRails ? 0 : 0xFFFFFFFF
        physicsBody?.usesPreciseCollisionDetection = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(deltaTime: TimeInterval) throws {
        let dT = deltaTime * Double(speed)
        localTime += dT

        if onRails {
            let (position, speed) = try orbitalParameters.cartesianState(after: localTime)
            let referencePosition = Vector(reference.position)

            self.position = (position + referencePosition).cgPoint
            self.physicsBody?.velocity = speed.cgVector
        } else {
            // Update the orbital parameters in order for the orbitalLine to get updated
            if !(orbitalParameters?.isHyperbolic ?? false) {
                updateOrbit()
            }

            // Calculate and apply the gravitational force
            let G: CGFloat = gravitationalConstant
            guard let m1 = physicsBody?.mass, let m2 = reference.physicsBody?.mass else { return }
            let pVec = Vector(position) - Vector(reference.position)
            let npVecNorm = pVec.normalized()
            let r = pVec.length
            let F = (G * m1 * m2) / pow(r, 2)
            let FVec = npVecNorm * -F
            self.physicsBody?.applyForce(FVec.cgVector)

            // Calculate and apply the drag force
            let altitude = heightAboveTerrain
            let densityAtSeaLevel: CGFloat = 1.2250 // Pa
            let gravitationalAcceleration: CGFloat = 9.80665 // m / s^2
            let molarMassOfAir: CGFloat = 0.0289644
            let universalGasConstant: CGFloat = 8.31432
            let temperature: CGFloat = 250.0 // kelvin
            let airDensity = densityAtSeaLevel * exp(-gravitationalAcceleration * molarMassOfAir * altitude / (universalGasConstant * temperature)) // Pa

            let referenceArea: CGFloat = 12.0 // m^2
            let dragCoefficient: CGFloat = 1.05
            let velocity = Vector(physicsBody!.velocity)
            let dragForce = dragCoefficient / 2 * airDensity * pow(velocity.length, 2) * referenceArea
            let dragForceVector = dragForce * -velocity.normalized()
            self.physicsBody?.applyForce(dragForceVector.cgVector)

            let dragAcceleration = dragForce / self.physicsBody!.mass
            let dragGForces = dragAcceleration / gravitationalAcceleration
            if dragGForces > 0.5 {
                print(dragGForces)
            }
        }

        redrawPosition()
    }

    func updateOrbit() {
        let planetPosition = Vector(reference.position)
        let entityPosition = Vector(position)

        let G = gravitationalConstant
        let mu = G * reference.bodyMass
        let eci = entityPosition - planetPosition
        let velocity = Vector(physicsBody!.velocity)

        localTime = 0
        orbitalParameters = OrbitalParameters(positionVector: eci, velocityVector: velocity, gravitationalConstant: mu)
        redrawOrbit()
        redrawPosition()
    }

    func redrawOrbit() {
        // TODO Don't draw orbit when we are on the ground.
        guard !orbitalParameters.isHyperbolic else {
            orbitalLine.path = nil
            // TODO Hide the apo-/periapsis markers
            return
        }

        let (scale, translation, vp) = displayState

        // Fade out the orbit when zooming in
        let orbitAlpha = 1.0 - scale * 2
        orbitalLine.alpha = orbitAlpha
        apoapsisMarker.alpha = orbitAlpha
        periapsisMarker.alpha = orbitAlpha

        if orbitAlpha > 0.0 {
            // Update the apoapsis and periapsis markers
            apoapsisMarker.position = (orbitalParameters.apoapsis.position * scale + translation).cgPoint
            periapsisMarker.position = (orbitalParameters.periapsis.position * scale + translation).cgPoint

            // Orbit path that is in the viewport
            // (although the way of only drawing only the visible portion is kinda crude ... sorry)
            let path = CGMutablePath()
            let points = orbitalParameters.orbitPath().map {
                CGPoint(x: $0.x * scale + translation.x, y: $0.y * scale + translation.y)
            }.filter { $0.isWithin(rect: vp, marginOfError: 5000.0) }
            path.addLines(between: points)
            orbitalLine.path = path
        }
    }

    func redrawPosition() {
        positionMarker.position = (Vector(position) * displayState.scale + displayState.translation).cgPoint
    }
}

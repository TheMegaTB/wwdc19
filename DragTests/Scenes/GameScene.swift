//
//  GameScene.swift
//  DragTests
//
//  Created by Til Blechschmidt on 15.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit
import GameplayKit

enum SimulationState {
    case onRails(speed: CGFloat)
    case physics(speed: CGFloat)
}

typealias DisplayState = (scale: CGFloat, translation: Vector, rotation: CGFloat, viewport: CGRect)

public class GameScene: SKScene {

    var simulationState: SimulationState = .onRails(speed: 1000) {
        didSet {
            switch simulationState {
            case .onRails(_):
                // "Disable" the physics simulation
                scene?.physicsWorld.speed = 0
            case .physics(let speed):
                // "Enable" the physics simulation
                scene?.physicsWorld.speed = speed
            }

            // Update the entities
            orbitingEntities.forEach {
                updateSimulationState(of: $0)
            }
        }
    }

    private lazy var planet = PlanetNode.default(withDisplayState: displayState, andTargetAngle: CGFloat.random(in: 0.0...CGFloat.pi*2))
//    private let moveSwitch = SwitchNode(labelOn: "Create Mode", labelOff: "Move Mode")
    private let followSwitch = SwitchNode(text: "Follow-cam")
    private let velocityLabel = SKLabelNode(text: nil)
    private let heightLabel = SKLabelNode(text: nil)
    private let apoapsisLabel = SKLabelNode(text: nil)
    private let periapsisLabel = SKLabelNode(text: nil)

    private let rotateLeft = ButtonNode(text: "Turn left")
    private let rotateRight = ButtonNode(text: "Turn right")
    private let burn = ButtonNode(text: "Ignite engine")

    private let fuelGauge = Gauge(text: "Fuel", width: 250, topLabel: true)
    private let heatGauge = Gauge(text: "Capsule heat", width: 250, topLabel: true, color: SKColor.red)
    private let heatShieldGauge = Gauge(text: "Heat shield", width: 250, color: SKColor.red)

    private var timewarpSlider: TimeWarpSlider!

    private let stars = SKEmitterNode(fileNamed: Emitter.stars)!

    private var previousCameraScale: CGFloat = 1.0
    private var currentUpdateCycleDT: TimeInterval = 0
    private var lastUpdateTime : TimeInterval = 0

    public override func sceneDidLoad() {
        self.lastUpdateTime = 0
    }

    public override func didMove(to view: SKView) {
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: 0, y: 0)
        cameraNode.setScale(Camera.defaultScale)
        let scalingAction = SKAction.scale(to: 1, duration: 3)
        scalingAction.timingMode = .easeOut
        let delayedScaling = SKAction.sequence([
            SKAction.wait(forDuration: 2),
            scalingAction
        ])
        // TODO This closure is escaping -> make self weak. [unowned self] doesn't work oddly enough
        cameraNode.run(delayedScaling) {
            self.timewarpSlider.snapHandleToPosition(position: 0)
        }

        followSwitch.state = true

        addChild(cameraNode)
        camera = cameraNode

        cameraNode.addChild(stars)

//        moveSwitch.position = CGPoint(x: -50, y: 200)
//        cameraNode.addChild(moveSwitch)

        var centerYOffset = 210
        if let height = UIScreen.main.currentMode?.size.height, height < 2700 {
            centerYOffset = 150
        }

        velocityLabel.position = CGPoint(x: 120, y: centerYOffset + 80)
        velocityLabel.fontSize = 25
        velocityLabel.zPosition = Layer.ui
        cameraNode.addChild(velocityLabel)

        heightLabel.position = CGPoint(x: 120, y: centerYOffset + 110)
        heightLabel.fontSize = 25
        heightLabel.zPosition = Layer.ui
        cameraNode.addChild(heightLabel)

        apoapsisLabel.position = CGPoint(x: -120, y: centerYOffset + 110)
        apoapsisLabel.fontSize = 25
        apoapsisLabel.zPosition = Layer.ui
        cameraNode.addChild(apoapsisLabel)

        periapsisLabel.position = CGPoint(x: -120, y: centerYOffset + 80)
        periapsisLabel.fontSize = 25
        periapsisLabel.zPosition = Layer.ui
        cameraNode.addChild(periapsisLabel)

        rotateLeft.position = CGPoint(x: -50, y: -centerYOffset - 40)
        cameraNode.addChild(rotateLeft)

        rotateRight.position = CGPoint(x: 50, y: -centerYOffset - 40)
        cameraNode.addChild(rotateRight)

        followSwitch.position = CGPoint(x: -50, y: -centerYOffset - 80)
        cameraNode.addChild(followSwitch)

        burn.position = CGPoint(x: 50, y: -centerYOffset - 80)
        burn.callback = { [unowned self] enabled in
            self.orbitingEntities.first?.thrusterState = enabled
        }
        cameraNode.addChild(burn)

        fuelGauge.position = CGPoint(x: 0, y: -centerYOffset)
        cameraNode.addChild(fuelGauge)

        heatGauge.position = CGPoint(x: 0, y: -centerYOffset - 140)
        cameraNode.addChild(heatGauge)

        heatShieldGauge.position = CGPoint(x: 0, y: -centerYOffset - 155)
        cameraNode.addChild(heatShieldGauge)

        timewarpSlider = TimeWarpSlider() { [unowned self] newState in
            self.simulationState = newState
        }
        timewarpSlider.position = CGPoint(x: 0, y: centerYOffset + 10)
        timewarpSlider.snapHandleToPosition(position: 3)
        cameraNode.addChild(timewarpSlider)

        self.physicsWorld.gravity =  CGVector(dx: 0.0, dy: 0.0)
        self.view?.backgroundColor = SKColor.darkGray

        addChild(planet)
        cameraNode.addChild(planet.scaledRepresentation)

        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.addTarget(self, action: #selector(pinchGestureAction(_:)))
        view.addGestureRecognizer(pinchGesture)

        createEntity(at: CGPoint(x: planet.bodyRadius + 411000, y: 0))
    }

    @objc private func pinchGestureAction(_ sender: UIPinchGestureRecognizer) {
        guard let camera = self.camera else {
            return
        }

        if sender.state == .began {
            previousCameraScale = camera.xScale
        }

        // Calculate new scale clamped to [1, inf)
        let newScale = previousCameraScale / sender.scale
        camera.setScale(newScale < 1 ? 1 : newScale)

        // TODO Move the camera according to the position of the pinch

        propagateDisplayState()
    }

    private var orbitingEntities: [OrbitingNode] = []

    func createEntity(at position: CGPoint) {
        let p = OrbitingNode(reference: planet, displayState: displayState)
        p.position = position
        p.physicsBody?.angularDamping = 0.75

        // Generate a random orbit
//        let eccentricity: CGFloat = CGFloat.random(in: 0.1..<0.5)
//        let semiMajorAxis: CGFloat = CGFloat.random(in: (planet.bodyRadius + 105_000) ... (planet.bodyRadius + 500_000)) //* 1/eccentricity
//        p.orbitalParameters = OrbitalParameters(
//            semiMajorAxis: semiMajorAxis,
//            eccentricity: eccentricity,
//            gravitationalConstant: Simulation.gravitationalConstant * planet.bodyMass
//        )
        p.updateOrbit()
        updateSimulationState(of: p)
        
        camera?.addChild(p.orbitalLine)
        camera?.addChild(p.apoapsisMarker)
        camera?.addChild(p.periapsisMarker)
        camera?.addChild(p.positionMarker)
        addChild(p)

        orbitingEntities.append(p)
    }

    private func updateSimulationState(of entity: OrbitingNode) {
        switch simulationState {
        case .onRails(let speed):
            // Put entities on rails
            entity.onRails = true
            entity.speed = speed
        case .physics(let speed):
            // Take entities off rails
            entity.onRails = false
            entity.speed = speed
        }
    }

//    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        // Spawn a new dot when you press with one finger
//        if touches.count == 1 && moveSwitch.state {
//            let scaledTouchPosition = touches.first!.location(in: self)
//            createEntity(at: scaledTouchPosition)
//        }
//    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if !followSwitch.state { // && !moveSwitch.state
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)

            camera?.position.x -= location.x - previousLocation.x
            camera?.position.y -= location.y - previousLocation.y

            propagateDisplayState()
        }
    }

    private func updateOrbitingEntities(deltaTime dt: TimeInterval) {
        // Updating gravity affected objects
        orbitingEntities = orbitingEntities.compactMap {
            do {
                try $0.update(deltaTime: dt)
                return $0
            } catch {
                if $0.onRails {
                    print("Encountered error processing object on-rails:", error, $0.orbitalParameters)
                    simulationState = .physics(speed: 1)
                    return $0
                } else {
                    print("Encountered fatal error processing object off-rails:", error)
                }
            }
            $0.removeFromParent()
            return nil
        }
    }

    public override func update(_ currentTime: TimeInterval) {

        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        self.lastUpdateTime = currentTime

        // Update the position of all entities
        updateOrbitingEntities(deltaTime: dt)

        guard let entity = orbitingEntities.first else { return }

        // Limit the time/physics warp speed
        let atmoHeight = Planet.atmosphereHeight
        let entityHeight = entity.heightAboveTerrain

        if entityHeight < 250 {
            timewarpSlider.stepLimit = 0
        } else if entityHeight < 1000 {
            timewarpSlider.stepLimit = 1
        } else if entityHeight < atmoHeight {
            timewarpSlider.stepLimit = 2
        } else if entityHeight < atmoHeight + 1000 {
            timewarpSlider.stepLimit = 3
        } else if entityHeight < atmoHeight + 120000 {
            timewarpSlider.stepLimit = 4
        } else {
            timewarpSlider.stepLimit = 6
        }

        // Rotate the capsule
        let angularImpulse: CGFloat = 0.25
        if rotateLeft.pushed {
            entity.physicsBody?.applyAngularImpulse(angularImpulse)
        } else if rotateRight.pushed {
            entity.physicsBody?.applyAngularImpulse(-angularImpulse)
        }

        // Update the fuel gauge
        if burn.pushed {
            fuelGauge.setFill(percentage: CGFloat(entity.remainingBurnTime / Capsule.secondsOfThrust))
        }

        // Update the heat shield
        heatShieldGauge.setFill(percentage: entity.remainingHeatShield / Capsule.heatShieldCapacity)
        heatGauge.setFill(percentage: entity.heat / Capsule.heatLimit)
    }

    public override func didSimulatePhysics() {
        if let entity = orbitingEntities.first, let physicsBody = entity.physicsBody {
            // Update the height label
            heightLabel.text = String(format: "Height: %.2f km", entity.heightAboveTerrain / 1000)

            // Update the velocity label
            let velocity = Vector(physicsBody.velocity).length
            velocityLabel.text = String(format: "Velocity: %.0f m/s", velocity)

            // Update apoapsis and periapsis label
            apoapsisLabel.text = String(format: "Apoapsis: %.0f km", entity.apoapsisHeight / 1000)
            periapsisLabel.text = String(format: "Periapsis: %.0f km", entity.periapsisHeight / 1000)
        }

        guard let camera = camera, let entity = orbitingEntities.first else {
            return
        }

        // Realign the camera if we are in follow mode
        if followSwitch.state {
            camera.position = orbitingEntities[0].position
        }

        // Orient the camera towards the planet if inside the atmosphere and follow mode is on
        if followSwitch.state && entity.insideAtmosphere {
            let defaultVector = Vector(planet.position) + Vector(0, 1, 0)
            let currentVector = Vector(camera.position) - Vector(planet.position)
            let angle = atan2(currentVector.y - defaultVector.y, currentVector.x - defaultVector.x)
            camera.run(SKAction.rotate(toAngle: angle - CGFloat.pi / 2, duration: 1.5, shortestUnitArc: true))
        }

        // Reset the camera rotation
        if (!entity.insideAtmosphere || !followSwitch.state) && camera.zRotation != 0 {
            camera.run(SKAction.rotate(toAngle: 0, duration: 1.5, shortestUnitArc: true))
        }

        propagateDisplayState()
    }

    public override func didFinishUpdate() {
        guard let entity = orbitingEntities.first else { return }

        // End the game when the entity is stranded in orbit
        if entity.remainingBurnTime <= 0.0 && entity.periapsisHeight > planet.atmosphereHeight {
            endGame(endState: .died(reason: .strandedInOrbit))
        }

        // End the game when the capsule has been evaporated
        if entity.heat > Capsule.heatLimit {
            endGame(endState: .died(reason: .evaporated))
        }

        // End the game when the entity has landed
        if entity.landed {
            let targetAngle = (planet.targetAngle + CGFloat.pi).truncatingRemainder(dividingBy: 2 * CGFloat.pi)
            let currentAngle = (entity.currentReferenceAngle + CGFloat.pi).truncatingRemainder(dividingBy: 2 * CGFloat.pi)
            let deltaAngle = max(targetAngle, currentAngle) - min(targetAngle, currentAngle)
            let closenessFactor = abs(1 - deltaAngle / CGFloat.pi) // 1 = on-spot, 0 = furthest it gets
            let landingSpotScore = Game.landingSpotScore * closenessFactor

            let remainingFuelPercentage = CGFloat(entity.remainingBurnTime / Capsule.secondsOfThrust)
            let remainingFuelScore = Game.remainingFuelScore * remainingFuelPercentage

            let score = Int(round(landingSpotScore + remainingFuelScore)) // TODO Add remaining fuel score
            var gameEndState: GameEndState = .landed(score: score)

            if entity.highestAcceleration > Game.maximumAcceleration {
                gameEndState = .died(reason: DeathReason.crushedToBits(acceleration: entity.highestAcceleration))
            }

            endGame(endState: gameEndState)
        }
    }

    private func endGame(endState: GameEndState) {
        let gameEndedScene = GameEndedScene(size: self.size, gameEndState: endState)
        gameEndedScene.scaleMode = .aspectFill
        self.scene!.view!.presentScene(gameEndedScene, transition: SKTransition.crossFade(withDuration: 1))
    }

    private var displayState: DisplayState {
        guard let camera = camera else { return (scale: 1, translation: [0, 0], rotation: 0, viewport: frame) }

        let scale = 1 / camera.xScale
        let translation = -Vector(camera.position) * scale
        let frameOriginInScene = convertPoint(fromView: frame.origin)
        let frameOriginInCamera = convert(frameOriginInScene, to: camera)
        let viewport = CGRect(
            origin: CGPoint(x: frameOriginInCamera.x, y: -frameOriginInCamera.y),
            size: frame.size
        )

        return (scale: scale, translation: translation, rotation: -camera.zRotation, viewport: viewport)
    }

    private func propagateDisplayState() {
        orbitingEntities.forEach {
            $0.displayState = displayState
        }
        planet.displayState = displayState

        stars.position = displayState.translation.cgPoint
        stars.zRotation = displayState.rotation
    }
}

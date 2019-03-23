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

class GameScene: SKScene {

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

    func updateSimulationState(of entity: OrbitingNode) {
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

    private lazy var planet = PlanetNode.default(withDisplayState: displayState, andTargetAngle: 4.1)
    private let moveSwitch = SwitchNode(labelOn: "Create Mode", labelOff: "Move Mode")
    private let followSwitch = SwitchNode(labelOn: "Follow", labelOff: "Freecam")
    private let velocityLabel = SKLabelNode(text: nil)
    private let heightLabel = SKLabelNode(text: nil)
    private let apoapsisLabel = SKLabelNode(text: nil)
    private let periapsisLabel = SKLabelNode(text: nil)

    private let progradeBoostButton = ButtonNode(text: "Boost")
    private let retrogradeBoostButton = ButtonNode(text: "Break")

    private var previousCameraScale: CGFloat = 1.0
    private var currentUpdateCycleDT: TimeInterval = 0
    private var lastUpdateTime : TimeInterval = 0

    override func sceneDidLoad() {
        self.lastUpdateTime = 0
    }

    override func didMove(to view: SKView) {
        /* Setup your scene here */
        simulationState = .onRails(speed: 1000)

        // Camera stuff
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: 0, y: 0)
        let scalingAction = SKAction.scale(to: Camera.defaultScale, duration: 5)
        scalingAction.timingMode = .easeOut
        cameraNode.run(scalingAction)

        addChild(cameraNode)
        camera = cameraNode

        followSwitch.position = CGPoint(x: 0, y: 250)
        cameraNode.addChild(followSwitch)

        moveSwitch.position = CGPoint(x: -50, y: 200)
        cameraNode.addChild(moveSwitch)

        velocityLabel.position = CGPoint(x: 0, y: 290)
        velocityLabel.fontSize = 25
        velocityLabel.zPosition = Layer.ui
        cameraNode.addChild(velocityLabel)

        heightLabel.position = CGPoint(x: 0, y: 320)
        heightLabel.fontSize = 25
        heightLabel.zPosition = Layer.ui
        cameraNode.addChild(heightLabel)

        retrogradeBoostButton.position = CGPoint(x: -50, y: -250)
        cameraNode.addChild(retrogradeBoostButton)

        progradeBoostButton.position = CGPoint(x: 50, y: -250)
        cameraNode.addChild(progradeBoostButton)

        apoapsisLabel.position = CGPoint(x: 0, y: -300)
        apoapsisLabel.fontSize = 25
        apoapsisLabel.zPosition = Layer.ui
        cameraNode.addChild(apoapsisLabel)

        periapsisLabel.position = CGPoint(x: 0, y: -330)
        periapsisLabel.fontSize = 25
        periapsisLabel.zPosition = Layer.ui
        cameraNode.addChild(periapsisLabel)

        let timewarpButton = SwitchNode(labelOn: "Off-Rails", labelOff: "On-Rails") { [unowned self] newState in
            if newState {
                self.simulationState = .physics(speed: 1)
            } else {
                self.simulationState = .onRails(speed: 1000)
            }
        }
        timewarpButton.position = CGPoint(x: 50, y: 200)
        cameraNode.addChild(timewarpButton)

        self.physicsWorld.gravity =  CGVector(dx: 0.0, dy: 0.0)
        self.view?.backgroundColor = SKColor.darkGray

        addChild(planet)
        cameraNode.addChild(planet.scaledRepresentation)

        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.addTarget(self, action: #selector(pinchGestureAction(_:)))
        view.addGestureRecognizer(pinchGesture)

        // Testing
        createEntity(at: CGPoint(x: planet.bodyRadius + 411000, y: 0))
    }


    @objc func pinchGestureAction(_ sender: UIPinchGestureRecognizer) {
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

    var orbitingEntities: [OrbitingNode] = []

    func createEntity(at position: CGPoint) {
        let p = OrbitingNode(reference: planet, displayState: displayState)
        p.position = position
        p.updateOrbit()
        updateSimulationState(of: p)
        print(p.orbitalParameters)
        camera?.addChild(p.orbitalLine)
        camera?.addChild(p.apoapsisMarker)
        camera?.addChild(p.periapsisMarker)
        camera?.addChild(p.positionMarker)
        addChild(p)

        orbitingEntities.append(p)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Spawn a new dot when you press with one finger
        if touches.count == 1 && moveSwitch.state {
            let scaledTouchPosition = touches.first!.location(in: self)
            createEntity(at: scaledTouchPosition)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if !moveSwitch.state && !followSwitch.state {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)

            camera?.position.x -= location.x - previousLocation.x
            camera?.position.y -= location.y - previousLocation.y

            propagateDisplayState()
        }
    }

    func updateOrbitingEntities(deltaTime dt: TimeInterval) {
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

        // Add boost to orbiting entity 0
        if let physicsEntity = orbitingEntities.first?.physicsBody {
            let force = Vector(physicsEntity.velocity).normalized() * Capsule.thrust
            if progradeBoostButton.pushed {
                physicsEntity.applyForce(force.cgVector)
            } else if retrogradeBoostButton.pushed {
                physicsEntity.applyForce((-force).cgVector)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Limit the time/physics warp speed
        // - No rails warp in atmosphere
        // - Rails warp only at speed=100 below 220km
        // - Physics warp only at speed=1 below 1km
        if let entity = self.orbitingEntities.first {
            let atmoHeight = Planet.atmosphereHeight
            let entityHeight = entity.heightAboveTerrain

            switch simulationState {
            case .onRails(let speed):
                if entityHeight < atmoHeight {
                    simulationState = .physics(speed: 10)
                } else if entityHeight < atmoHeight + 120000 && speed > 1 {
                    simulationState = .onRails(speed: 100)
                }
            case .physics(let speed):
                if entityHeight < 1000 && speed > 1 {
                    simulationState = .physics(speed: 1)
                }
            }
        }

        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        self.lastUpdateTime = currentTime

        // Update the position of all entities
        updateOrbitingEntities(deltaTime: dt)
    }

    override func didSimulatePhysics() {
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

    override func didFinishUpdate() {
        if let entity = orbitingEntities.first, entity.landed {
            let targetAngle = (planet.targetAngle + CGFloat.pi).truncatingRemainder(dividingBy: 2 * CGFloat.pi)
            let currentAngle = (entity.currentReferenceAngle + CGFloat.pi).truncatingRemainder(dividingBy: 2 * CGFloat.pi)
            // TODO The deltaAngle can be negative. Fix it
            let deltaAngle = max(targetAngle, currentAngle) - min(targetAngle, currentAngle)
            let closenessFactor = 1 - deltaAngle / CGFloat.pi // 1 = on-spot, 0 = furthest it gets
            let landingSpotScore = Game.landingSpotScore * closenessFactor

            let score = Int(round(landingSpotScore)) // TODO Add remaining fuel score
            var gameEndState: GameEndState = .landed(score: score)

            if entity.highestAcceleration > Game.maximumAcceleration {
                gameEndState = .died(reason: DeathReason.crushedToBits(acceleration: entity.highestAcceleration))
            }

            let gameEndedScene = GameEndedScene(size: self.size, gameEndState: gameEndState)
            gameEndedScene.scaleMode = .aspectFill
            self.scene!.view!.presentScene(gameEndedScene, transition: SKTransition.crossFade(withDuration: 1))
        }
    }

    var displayState: DisplayState {
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

    func propagateDisplayState() {
        orbitingEntities.forEach {
            $0.displayState = displayState
        }
        planet.displayState = displayState
    }
}

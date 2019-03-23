//
//  PlanetNode.swift
//  DragTests
//
//  Created by Til Blechschmidt on 19.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class PlanetNode: SKShapeNode {
    let bodyMass: CGFloat
    let bodyRadius: CGFloat
    let atmosphereHeight: CGFloat
    let scaledRepresentation = SKShapeNode()
    private let atmosphereBorder: SKShapeNode
    private let targetMarker = TargetMarker()

    var targetAngle: CGFloat {
        didSet {
            redraw()
        }
    }

    var displayState: DisplayState {
        didSet {
            redraw()
        }
    }

    init(mass: CGFloat, radius: CGFloat, atmosphereRadius: Float, displayState: DisplayState, targetAngle: CGFloat) {
        self.bodyMass = mass
        self.bodyRadius = radius
        self.atmosphereHeight = CGFloat(atmosphereRadius) - radius
        self.displayState = displayState
        self.targetAngle = targetAngle
        atmosphereBorder = SKShapeNode(circleOfRadius: CGFloat(atmosphereRadius))

        super.init()

        redraw()

        // Hide this planet. It will only be used for positioning and physics
        strokeColor = SKColor.clear

        // Add a physics body
        physicsBody = SKPhysicsBody(circleOfRadius: bodyRadius)
        physicsBody?.mass = bodyMass
        physicsBody?.pinned = true
        physicsBody?.collisionBitMask = 1
        physicsBody?.usesPreciseCollisionDetection = true

        // Add a visual representation of the atmosphere
        let atmosphereVisualization = SKShapeNode(circleOfRadius: radius)
        atmosphereVisualization.strokeColor = SKColor.blue
        atmosphereVisualization.alpha = 0.5
        atmosphereVisualization.glowWidth = CGFloat(atmosphereRadius) - radius
        atmosphereVisualization.zPosition = Layer.atmosphere
        addChild(atmosphereVisualization)

        // Add a visual border to the atmosphere
        atmosphereBorder.strokeColor = SKColor.white
        atmosphereBorder.strokeShader = Shader.stroked
        atmosphereBorder.zPosition = Layer.atmosphere
        atmosphereBorder.lineWidth = 500
        addChild(atmosphereBorder)

        // Setup a planet representation for precise drawing
        scaledRepresentation.fillColor = SKColor.orange
        scaledRepresentation.strokeColor = SKColor.orange
        scaledRepresentation.zPosition = Layer.entity

        scaledRepresentation.addChild(targetMarker)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw() {
        // Hide the atmosphere border if zoomed out too far
        let borderScale = 1 / (displayState.scale * 2000) - 1
        // Hidden if scale < 0.0005
        // Gradually fade in until 0.00045
        atmosphereBorder.alpha = 1 - min(1, max(0, borderScale))

        // Scaled circle parameters
        let midpoint = (Vector(position) * displayState.scale + displayState.translation).cgPoint.rotated(by: displayState.rotation)
        let radius = bodyRadius * displayState.scale

        // Calculate the points of intersection of the circle and the viewport borders
        let vp = displayState.viewport
        let A = CGPoint(x: vp.minX, y: vp.minY)
        let B = CGPoint(x: vp.minX, y: vp.maxY)
        let C = CGPoint(x: vp.maxX, y: vp.maxY)
        let D = CGPoint(x: vp.maxX, y: vp.minY)

        let leftIntersection = intersection(ofLineFrom: A, to: B, withCircleAt: midpoint, radius: radius)
        let topIntersection = intersection(ofLineFrom: B, to: C, withCircleAt: midpoint, radius: radius)
        let rightIntersection = intersection(ofLineFrom: C, to: D, withCircleAt: midpoint, radius: radius)
        let bottomIntersection = intersection(ofLineFrom: D, to: A, withCircleAt: midpoint, radius: radius)

        let leftPoints = leftIntersection.points(within: vp)
        let topPoints = topIntersection.points(within: vp)
        let rightPoints = rightIntersection.points(within: vp)
        let bottomPoints = bottomIntersection.points(within: vp)

        var points: [CGPoint] = [leftPoints, topPoints, rightPoints, bottomPoints].flatMap { $0 }

        if points.count == 2 {
            let p1 = points[0]
            let p2 = points[1]

            // Angles of the points in the range [0, 2*pi] (note that they are offset by pi)
            let p1Angle = atan2(p1.y - midpoint.y, p1.x - midpoint.x) + CGFloat.pi
            let p2Angle = atan2(p2.y - midpoint.y, p2.x - midpoint.x) + CGFloat.pi

            let startAngle = min(p1Angle, p2Angle)
            let endAngle = max(p1Angle, p2Angle)
            let arcLength = endAngle - startAngle

            let samplePoint = CGPoint.onCircle(angle: startAngle + arcLength / 2.0, circlePosition: midpoint, circleRadius: radius)
            let flipped = samplePoint.isWithin(rect: vp, marginOfError: 0.01)

            var circlePoints: [CGPoint] = []

            let segments = 500
            if flipped {
                // Draw endAngle -> 2pi + startAngle
                let flippedArcLength = (2 * CGFloat.pi + startAngle) - endAngle
                var angle = endAngle
                for _ in 0..<segments {
                    circlePoints.append(CGPoint.onCircle(angle: angle - CGFloat.pi, circlePosition: midpoint, circleRadius: radius))
                    angle += (flippedArcLength / CGFloat(segments))
                }
            } else {
                // Draw an arc from startAngle -> endAngle
                var angle = startAngle
                for _ in 0..<segments {
                    circlePoints.append(CGPoint.onCircle(angle: angle - CGFloat.pi, circlePosition: midpoint, circleRadius: radius))
                    angle += (arcLength / CGFloat(segments))
                }
            }

            // Add the corners of the edges crossed by the circle
            // TODO Their order may be wrong though ...
            let cornerPoints = [A, B, C, D].filter { $0.isContainedBy(circleAt: midpoint, withRadius: radius) }
            let orderedCorners = order(start: circlePoints.last!, points: cornerPoints)
//            print("\(flipped)\n\(circlePoints.first!)\n\(circlePoints.last!)\n\(cornerPoints)\n")
            circlePoints += orderedCorners

            let path = CGMutablePath()
            path.addLines(between: circlePoints)
            scaledRepresentation.path = path
        } else {
            scaledRepresentation.path = CGPath.circle(at: midpoint, ofRadius: radius)
        }

        targetMarker.position = CGPoint.onCircle(
            angle: targetAngle + displayState.rotation,
            circlePosition: midpoint,
            circleRadius: radius
        )
    }
}

extension PlanetNode {
    static func `default`(withDisplayState: DisplayState, andTargetAngle: CGFloat) -> PlanetNode {
        return PlanetNode(
            mass: Planet.mass,
            radius: Planet.radius,
            atmosphereRadius: Float(Planet.radius + Planet.atmosphereHeight),
            displayState: withDisplayState,
            targetAngle: andTargetAngle
        )
    }
}

fileprivate func order(start: CGPoint, points: [CGPoint]) -> [CGPoint] {
    var remainingPoints = points
    var resultingPoints: [CGPoint] = []
    var previousPoint = start

    while let next = remainingPoints.first(where: { $0.roughlyOnSameAxisAs(previousPoint) }) {
        resultingPoints.append(next)
        remainingPoints.removeAll { $0 == next }
        previousPoint = next
    }

    return resultingPoints
}

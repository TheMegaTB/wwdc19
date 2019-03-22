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
    let scaledRepresentation = SKShapeNode()

    var displayState: DisplayState {
        didSet {
            redraw()
        }
    }

    init(mass: CGFloat, radius: CGFloat, atmosphereRadius: Float, displayState: DisplayState) {
        self.bodyMass = mass
        self.bodyRadius = radius
        self.displayState = displayState

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

        // Add a dragging atmosphere
//        let atmosphere = SKFieldNode.dragField()
//        atmosphere.region = SKRegion(radius: atmosphereRadius)
//        atmosphere.minimumRadius = Float(radius)
//        atmosphere.strength = 1_000_000
//        atmosphere.falloff = 1
//        addChild(atmosphere)

        // Add a visual representation of the atmosphere
        let atmosphereVisualization = SKShapeNode(circleOfRadius: radius)
        atmosphereVisualization.strokeColor = SKColor.blue
        atmosphereVisualization.alpha = 0.5
        atmosphereVisualization.glowWidth = CGFloat(atmosphereRadius) - radius
        atmosphereVisualization.zPosition = 1
        addChild(atmosphereVisualization)

        // Setup a planet representation for precise drawing
        scaledRepresentation.fillColor = SKColor.orange
        scaledRepresentation.strokeColor = SKColor.orange
        scaledRepresentation.zPosition = 5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw() {
        self.path = CGPath.circle(at: position, ofRadius: bodyRadius)

        // Scaled circle parameters
        let midpoint = (Vector(position) * displayState.scale + displayState.translation).cgPoint
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
            circlePoints += [D, C, B, A].filter { $0.isContainedBy(circleAt: midpoint, withRadius: radius) }

            let path = CGMutablePath()
            path.addLines(between: circlePoints)
            scaledRepresentation.path = path
        } else {
            scaledRepresentation.path = CGPath.circle(at: midpoint, ofRadius: radius)
        }
    }
}

extension CGPoint {
    fileprivate static func onCircle(angle: CGFloat, circlePosition: CGPoint, circleRadius: CGFloat) -> CGPoint {
        return CGPoint(x: circlePosition.x + circleRadius * cos(angle), y: circlePosition.y + circleRadius * sin(angle))
    }
}

extension CGPath {
    fileprivate static func circle(at position: CGPoint, ofRadius radius: CGFloat) -> CGPath {
        let path = CGMutablePath()

        let size = CGSize(width: radius * 2, height: radius * 2)
        let origin = CGPoint(x: position.x - size.width/2, y: position.y - size.height/2)
        let rect = CGRect(origin: origin, size: size)

        path.addEllipse(in: rect)

        return path
    }
}

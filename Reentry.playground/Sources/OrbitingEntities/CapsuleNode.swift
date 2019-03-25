//
//  Capsule.swift
//  DragTests
//
//  Created by Til Blechschmidt on 23.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class CapsuleNode: SKShapeNode {
    let width: CGFloat
    let height: CGFloat
    let heatShieldHeight: CGFloat
    let dockingPortWidth: CGFloat

    init(scale: CGFloat = 1.0) {
        height = 230 * scale
        width = 250 * scale
        heatShieldHeight = width * 0.16
        dockingPortWidth = width * 0.56

        super.init()

        strokeColor = SKColor.lightGray
        fillColor = strokeColor

        var paths: [CGPath] = []
        paths.append(setCapsulePath())
        paths.append(addHeatShield())

        let physicsPath = CGMutablePath()
        physicsPath.addPath(self.path!)
        paths.forEach { physicsPath.addPath($0) }
        physicsBody = SKPhysicsBody(polygonFrom: physicsPath)
        physicsBody?.usesPreciseCollisionDetection = true
    }

    func setCapsulePath() -> CGPath {
        let sideWidth: CGFloat = width * 0.05
        let dockingPortY: CGFloat = height
        let midpointY: CGFloat = height * 0.457
        let hatchHeight: CGFloat = height * 0.52

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: 0))

        // Bottom line
        path.addLine(to: CGPoint(x: width / 2, y: 0))

        // Lower right curve
        let rightMidpoint = CGPoint(x: width / 2 - sideWidth, y: midpointY)
        path.addQuadCurve(to: rightMidpoint, control: CGPoint(x: width / 2, y: midpointY / 2))

        // Upper right curve
        let rightDockingPortPoint = CGPoint(x: dockingPortWidth / 2, y: dockingPortY)
        path.addQuadCurve(
            to: rightDockingPortPoint,
            control: CGPoint(
                x: rightMidpoint.x - (rightMidpoint.x - rightDockingPortPoint.x) / 2,
                y: dockingPortY - midpointY/2
            )
        )

        // Docking port curve
        let leftDockingPortPoint = CGPoint(x: -dockingPortWidth / 2, y: dockingPortY)
        path.addLine(to: leftDockingPortPoint)

        // Upper left curve
        let leftMidpoint = CGPoint(x: -width / 2 + sideWidth, y: midpointY)
        path.addQuadCurve(
            to: leftMidpoint,
            control: CGPoint(
                x: leftMidpoint.x - (leftMidpoint.x - leftDockingPortPoint.x) / 2,
                y: dockingPortY - midpointY/2
            )
        )

        // Lower left curve
        path.addQuadCurve(to: CGPoint(x: -width / 2, y: 0), control: CGPoint(x: -width / 2, y: midpointY / 2))
        path.closeSubpath()

        self.path = path

        // Hatch
        let hatchPath = CGMutablePath()
        hatchPath.move(to: rightDockingPortPoint)
        hatchPath.addQuadCurve(
            to: leftDockingPortPoint,
            control: CGPoint(x: 0, y: dockingPortY + hatchHeight)
        )

        let hatch = SKShapeNode(path: hatchPath)
        hatch.fillColor = SKColor.darkGray
        hatch.strokeColor = hatch.fillColor
        addChild(hatch)

        hatch.zPosition = Layer.entity

        return hatchPath
    }

    func addHeatShield() -> CGPath {
        let heatShieldPath = CGMutablePath()
        heatShieldPath.move(to: CGPoint(x: -width / 2, y: 0))
        heatShieldPath.addCurve(
            to: CGPoint(x: width / 2, y: 0),
            control1: CGPoint(x: -width / 2, y: -heatShieldHeight),
            control2: CGPoint(x: width / 2, y: -heatShieldHeight)
        )
        heatShieldPath.addLine(to: CGPoint(x: -width / 2, y: 0))
        heatShieldPath.closeSubpath()

        let heatShield = SKShapeNode(path: heatShieldPath)
        heatShield.fillColor = SKColor.red
        heatShield.strokeColor = heatShield.fillColor
        heatShield.zPosition = Layer.entity
        addChild(heatShield)

        return heatShieldPath
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  TargetMarker.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class TargetMarker: SKShapeNode {
    override init() {
        super.init()
        strokeColor = SKColor.red
        lineWidth = 5
        zPosition = Layer.target

        redraw()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw() {
        let lineLength: CGFloat = 10
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: lineLength, y: lineLength))
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: -lineLength, y: -lineLength))
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: -lineLength, y: lineLength))
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: lineLength, y: -lineLength))
        self.path = path
    }
}

//
//  Gauge.swift
//  DragTests
//
//  Created by Til Blechschmidt on 24.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class Gauge: SKNode {
    let rect: CGRect
    let border: SKShapeNode
    let fill = SKShapeNode()

    init(text: String, width: CGFloat, topLabel: Bool = false, color: SKColor = SKColor.orange, initial: CGFloat = 1.0) {
        let height: CGFloat = 10.0
        rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        border = SKShapeNode(rect: rect)
        border.strokeColor = SKColor.white
        fill.fillColor = color

        let label = SKLabelNode(text: text)
        label.position = CGPoint(x: 0, y: topLabel ? height + 5 : -height - 20)
        label.fontSize = 20

        super.init()
        addChild(label)
        addChild(border)
        addChild(fill)

        setFill(percentage: initial)

        fill.zPosition = Layer.ui
        border.zPosition = Layer.ui
        label.zPosition = Layer.ui
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFill(percentage: CGFloat) {
        let path = CGMutablePath()
        let rect = CGRect(
            origin: self.rect.origin,
            size: CGSize(width: self.rect.width * percentage, height: self.rect.size.height)
        )
        path.addRect(rect)

        fill.path = path
    }
}

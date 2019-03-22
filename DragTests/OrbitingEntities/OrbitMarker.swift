//
//  OrbitMarker.swift
//  DragTests
//
//  Created by Til Blechschmidt on 18.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class OrbitMarker: SKNode {
    let shapeNode: SKSpriteNode
    let labelNode: SKLabelNode

    override var alpha: CGFloat {
        didSet {
            super.alpha = alpha
            shapeNode.alpha = alpha
            labelNode.alpha = alpha
        }
    }

    init(label: String) {
        shapeNode = SKSpriteNode(color: SKColor.green, size: CGSize(width: 5, height: 5))
        shapeNode.position = CGPoint(x: 0, y: 0)

        labelNode = SKLabelNode(text: label)
        labelNode.fontSize = 15
        labelNode.position = CGPoint(x: 0, y: 10)

        super.init()
        addChild(shapeNode)
        addChild(labelNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

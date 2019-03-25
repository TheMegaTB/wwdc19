//
//  SwitchNode.swift
//  DragTests
//
//  Created by Til Blechschmidt on 19.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class SwitchNode: SKSpriteNode {
    let label: SKLabelNode
    let callback: ((Bool) -> ())?

    var state = false {
        didSet {
            color = state ? SKColor.red : SKColor.lightGray
            self.callback?(state)
        }
    }

    init(text: String, _ callback: ((Bool) -> ())? = nil) {
        self.callback = callback

        let size = CGSize(width: 100, height: 32)

        label = SKLabelNode(text: text)
        label.fontSize = 16
        label.zPosition = Layer.ui
        label.position = CGPoint(x: 0, y: label.fontSize / 2 - size.height / 2)

        super.init(texture: nil, color: SKColor.lightGray, size: size)

        addChild(label)
        zPosition = Layer.ui
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: parent!)
            if self.contains(location) {
                self.state = !state
            }
        }
    }
}

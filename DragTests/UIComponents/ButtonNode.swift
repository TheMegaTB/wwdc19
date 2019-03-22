//
//  ButtonNode.swift
//  DragTests
//
//  Created by Til Blechschmidt on 21.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class ButtonNode: SKSpriteNode {
    let label: SKLabelNode
    let callback: ((Bool) -> ())?

    private(set) var pushed: Bool = false {
        didSet {
            if pushed {
                color = SKColor.red
            } else {
                color = SKColor.cyan
            }
            callback?(pushed)
        }
    }

    init(text: String, _ callback: ((Bool) -> ())? = nil) {
        let size = CGSize(width: 100, height: 32)

        label = SKLabelNode(text: text)
        label.fontSize = 16
        label.fontColor = SKColor.black
        label.position = CGPoint(x: 0, y: label.fontSize / 2 - size.height / 2)

        self.callback = callback

        super.init(texture: nil, color: SKColor.cyan, size: size)

        addChild(label)
        zPosition = 10
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: parent!)
            if self.contains(location) {
                pushed = true
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pushed = false
    }
}

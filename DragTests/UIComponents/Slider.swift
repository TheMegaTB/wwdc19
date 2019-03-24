//
//  Slider.swift
//  DragTests
//
//  Created by Til Blechschmidt on 24.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

class Slider: SKNode {
    let width = 450
    let height = 25

    var stepLimit: Int {
        didSet {
            redrawStepLimit()
            if currentPosition > stepLimit {
                snapHandleToPosition(position: stepLimit)
            }
        }
    }

    private let limitBar = SKShapeNode()
    private let handle: SKShapeNode
    private let stepCount: Int
    private(set) var currentPosition = 0
    private var callback: ((Int) -> ())?

    private lazy var positionXValues: [CGFloat] = {
        let firstPosition = -CGFloat(width) / 2
        let stepWidth = CGFloat(width) / CGFloat(stepCount - 1)
        return (0..<stepCount).map { firstPosition + stepWidth * CGFloat($0) }
    }()

    var handleMoving = false

    init(steps: [String], callback: ((Int) -> ())? = nil) {
        let handleSize = Double(height) * 1.5
        handle = SKShapeNode(rectOf: CGSize(width: handleSize, height: handleSize), cornerRadius: 15)
        handle.strokeColor = SKColor.white
        handle.fillColor = handle.strokeColor

        self.stepLimit = steps.count
        self.stepCount = steps.count
        self.callback = callback

        super.init()

        let barWidth = CGFloat(width) + 30
        let barRect = CGRect(x: -barWidth / 2, y: -CGFloat(height) / 2, width: barWidth, height: CGFloat(height))
        let bar = SKShapeNode(rect: barRect, cornerRadius: 15)
        bar.strokeColor = SKColor.darkGray
        bar.fillColor = bar.strokeColor
        bar.alpha = 0.5

        // Add little bars and labels
        positionXValues.enumerated().forEach { value in
            let (i, x) = value
            let positionBarHeight = CGFloat(height + 10)
            let positionBarRect = CGRect(x: x, y: -positionBarHeight / 2, width: 1.0, height: positionBarHeight)
            let positionBar = SKShapeNode(rect: positionBarRect)
            positionBar.strokeColor = SKColor.lightGray
            positionBar.fillColor = positionBar.strokeColor
            positionBar.zPosition = Layer.ui + 1
            addChild(positionBar)

            let positionBarLabel = SKLabelNode(text: steps[i])
            positionBarLabel.fontSize = 16
            positionBarLabel.position = CGPoint(x: x, y: -positionBarHeight / 2 - 15)
            positionBarLabel.zPosition = Layer.ui
            addChild(positionBarLabel)
        }

        limitBar.strokeColor = SKColor.red.withAlphaComponent(0.5)
        limitBar.fillColor = limitBar.strokeColor

        // Set the zPositions
        zPosition = Layer.ui
        bar.zPosition = Layer.ui
        handle.zPosition = Layer.ui + 2

        // Enable user interaction
        isUserInteractionEnabled = true

        // Add child nodes
        addChild(bar)
        addChild(handle)
        addChild(limitBar)
        snapHandleToPosition(position: 0, animate: false)

        redrawStepLimit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redrawStepLimit() {
        guard stepLimit < stepCount else { return }
        let position = positionXValues[stepLimit]
        let stepWidth = CGFloat(width) / CGFloat(stepCount - 1)
        let segmentCount = stepCount - stepLimit - 1
        let bar = CGRect(x: position, y: -CGFloat(height) / 2, width: CGFloat(segmentCount) * stepWidth, height: CGFloat(height))
        let path = CGMutablePath()
        path.addRect(bar)
        limitBar.path = path
    }

    func snapHandleToPosition(position: Int, animate: Bool = true) {
        let position = position > stepLimit ? stepLimit : position
        let xPosition = positionXValues[position]
        let newPosition = CGPoint(x: xPosition, y: handle.position.y)
        currentPosition = position

        if animate {
            handle.run(SKAction.move(to: newPosition, duration: 0.25))
        } else {
            handle.position = newPosition
        }

        callback?(position)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            if handle.contains(location) {
                handleMoving = true
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, handleMoving {
            let x = touch.location(in: self).x
            guard x < CGFloat(width) / 2 && x > -CGFloat(width) / 2 else { return }
            handle.position = CGPoint(x: x, y: handle.position.y)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleMoving = false

        let positionXValues = self.positionXValues
        var previousDistance = CGFloat(width)
        var previousPosition = currentPosition

        for i in 0..<positionXValues.count {
            let distance = abs(positionXValues[i] - handle.position.x)
            if distance < previousDistance {
                previousPosition = i
                previousDistance = distance
            }
        }

        snapHandleToPosition(position: previousPosition)
    }
}

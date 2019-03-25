//
//  TimeWarpSlider.swift
//  DragTests
//
//  Created by Til Blechschmidt on 24.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SpriteKit

// Physics:
// 1x
// 4x
// 10x
// Rails:
// 100x
// 1000x
// 10000x

class TimeWarpSlider: Slider {
    init(callback: @escaping (SimulationState) -> ()) {
        let steps = [
            "1x",
            "4x",
            "10x",
            "100x",
            "1000x",
            "10000x"
        ]

        super.init(steps: steps) { position in
            let simulationState: SimulationState
            switch position {
            case 0:
                simulationState = .physics(speed: 1)
            case 1:
                simulationState = .physics(speed: 4)
            case 2:
                simulationState = .physics(speed: 10)
            case 3:
                simulationState = .onRails(speed: 10)
            case 4:
                simulationState = .onRails(speed: 100)
            case 5:
                simulationState = .onRails(speed: 1000)
            default:
                simulationState = .physics(speed: 1)
            }
            callback(simulationState)
        }

        let segmentWidth = CGFloat(super.width) / 2
        let labelY = CGFloat(super.height) / 2 + 20
        let barY = CGFloat(super.height) / 2 + 10

        let physicsLabel = SKLabelNode(text: "Physics warp")
        physicsLabel.position = CGPoint(x: -segmentWidth / 2, y: labelY)
        physicsLabel.fontSize = 20
        addChild(physicsLabel)

        let physicsBar = SKShapeNode(rectOf: CGSize(width: segmentWidth, height: 2))
        physicsBar.position = CGPoint(x: -segmentWidth / 2, y: barY)
        physicsBar.strokeColor = SKColor.green
        physicsBar.fillColor = physicsBar.strokeColor
        addChild(physicsBar)

        let railsLabel = SKLabelNode(text: "Rails warp")
        railsLabel.position = CGPoint(x: segmentWidth / 2, y: labelY)
        railsLabel.fontSize = 20
        addChild(railsLabel)

        let railsBar = SKShapeNode(rectOf: CGSize(width: segmentWidth, height: 2))
        railsBar.position = CGPoint(x: segmentWidth / 2, y: barY)
        railsBar.strokeColor = SKColor.red
        railsBar.fillColor = railsBar.strokeColor
        addChild(railsBar)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

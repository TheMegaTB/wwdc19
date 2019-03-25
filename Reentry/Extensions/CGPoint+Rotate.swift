//
//  CGPoint+Rotate.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    func rotated(by angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: x * cos(angle) - y * sin(angle),
            y: x * sin(angle) + y * cos(angle)
        )
    }
}

//
//  CGPoint+IsWithin.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    func isWithin(rect: CGRect, marginOfError: CGFloat) -> Bool {
        return self.x >= rect.minX - marginOfError && self.x <= rect.maxX + marginOfError
            && self.y >= rect.minY - marginOfError && self.y <= rect.maxY + marginOfError
    }

    func isContainedBy(circleAt midpoint: CGPoint, withRadius radius: CGFloat) -> Bool {
        let distanceVector = CGVector(dx: self.x - midpoint.x, dy: self.y - midpoint.y)
        let distanceFromCenter = sqrt(pow(distanceVector.dx, 2) + pow(distanceVector.dy, 2))
        return distanceFromCenter < radius
    }

    func roughlyOnSameAxisAs(_ other: CGPoint, margin: CGFloat = 10.0) -> Bool {
        return abs(self.x - other.x) < margin || abs(self.y - other.y) < margin
    }
}

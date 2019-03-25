//
//  CoreGraphics+Circle.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    static func onCircle(angle: CGFloat, circlePosition: CGPoint, circleRadius: CGFloat) -> CGPoint {
        return CGPoint(x: circlePosition.x + circleRadius * cos(angle), y: circlePosition.y + circleRadius * sin(angle))
    }
}

extension CGPath {
    static func circle(at position: CGPoint, ofRadius radius: CGFloat) -> CGPath {
        let path = CGMutablePath()

        let size = CGSize(width: radius * 2, height: radius * 2)
        let origin = CGPoint(x: position.x - size.width/2, y: position.y - size.height/2)
        let rect = CGRect(origin: origin, size: size)

        path.addEllipse(in: rect)

        return path
    }
}

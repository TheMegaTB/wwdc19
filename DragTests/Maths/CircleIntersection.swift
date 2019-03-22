//
//  CircleIntersection.swift
//  DragTests
//
//  Created by Til Blechschmidt on 20.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreGraphics

fileprivate func sgn(_ x: CGFloat) -> CGFloat {
    return x < 0 ? -1 : 1
}

enum CircleIntersection {
    case passes
    case tangent(at: CGPoint)
    case intersects(p1: CGPoint, p2: CGPoint)

    func points() -> [CGPoint] {
        switch self {
        case .passes:
            return []
        case .tangent(let at):
            return [at]
        case .intersects(let p1, let p2):
            return [p1, p2]
        }
    }

    func points(within bounds: CGRect) -> [CGPoint] {
        let points = self.points()
        return points.filter { $0.isWithin(rect: bounds, marginOfError: 10.0) }
    }
}

func intersection(ofLineFrom lineStart: CGPoint, to lineEnd: CGPoint, withCircleAt center: CGPoint, radius: CGFloat) -> CircleIntersection {
    let lp1 = CGPoint(x: lineStart.x - center.x, y: lineStart.y - center.y)
    let lp2 = CGPoint(x: lineEnd.x - center.x, y: lineEnd.y - center.y)

    let dx = lp2.x - lp1.x
    let dy = lp2.y - lp1.y
    let dr = sqrt(pow(dx, 2) + pow(dy, 2))
    let D = lp1.x * lp2.y - lp2.x * lp1.y

    let drSq = pow(dr, 2)
    let formularSqrt = sqrt(pow(radius, 2) * drSq - pow(D, 2))

    let x1 = (D * dy + sgn(dy) * dx * formularSqrt) / drSq
    let x2 = (D * dy - sgn(dy) * dx * formularSqrt) / drSq

    let y1 = (-D * dx + abs(dy) * formularSqrt) / drSq
    let y2 = (-D * dx - abs(dy) * formularSqrt) / drSq

    let intersection1 = CGPoint(x: x1 + center.x, y: y1 + center.y)
    let intersection2 = CGPoint(x: x2 + center.x, y: y2 + center.y)

    let incidence = pow(radius, 2) * drSq - pow(D, 2)

    if incidence < 0.0 {
        return .passes
    } else if incidence == 0.0 {
        return .tangent(at: intersection1)
    } else { // incidence > 0.0
        return .intersects(p1: intersection1, p2: intersection2)
    }
}

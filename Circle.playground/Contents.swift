import CoreGraphics

fileprivate func sgn(_ x: CGFloat) -> CGFloat {
    return x < 0 ? -1 : 1
}

enum CircleIntersection {
    case passes
    case tangent(at: CGPoint)
    case intersects(p1: CGPoint, p2: CGPoint)
}

func intersection(ofLineFrom lineStart: CGPoint, to lineEnd: CGPoint, withCircleAt center: CGPoint, radius: CGFloat) -> CircleIntersection {
    // TODO Offset lineStart and lineEnd so this works with a circle that is not at (0,0)
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

    print(incidence)

    if incidence < 0.0 {
        return .passes
    } else if incidence == 0.0 {
        return .tangent(at: intersection1)
    } else { // incidence > 0.0
        return .intersects(p1: intersection1, p2: intersection2)
    }
}

//print(intersection(ofLineFrom: CGPoint(x: -3, y: 0),
//                   to: CGPoint(x: 3, y: 0),
//                   withCircleAt: CGPoint(x: 0, y: 2),
//                   radius: 2.0))


func iterate(from: CGFloat, to: CGFloat, limitedBy bound: CGFloat, clockwise: Bool, stepSize: CGFloat, closure: (CGFloat) -> ()) {
    let a = from < 0 ? from + bound : from
    let b = to < 0 ? to + bound : to

    let start = min(a, b)
    let end = max(a, b)

    print(start, end)

    let distance = end - start
    var currentStep = CGFloat(0.0)

    while currentStep <= distance {
        closure(clockwise ? start + currentStep : start - currentStep)
        currentStep += stepSize
    }
}

//iterate(from: -90.0, to: 90.0, limitedBy: 360.0, clockwise: true, stepSize: 1.0)
//iterate(from: 1.25, to: 5.0, limitedBy: CGFloat(2 * Double.pi), clockwise: false, stepSize: 0.1) { angle in
//    print(angle)
//}

let densityAtSeaLevel = 1.2250
let gravitationalAcceleration = 9.80665
let molarMassOfAir = 0.0289644
let universalGasConstant = 8.31432
let temperature = 273.15 + 20.0

for altitude in 0...100000 {
    let airDensity = densityAtSeaLevel * exp(-gravitationalAcceleration * molarMassOfAir * Double(altitude) / (universalGasConstant * temperature))
    print(altitude, airDensity)
}

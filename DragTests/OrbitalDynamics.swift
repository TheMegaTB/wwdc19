//
//  OrbitalDynamics.swift
//  DragTests
//
//  Created by Til Blechschmidt on 17.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreGraphics

precedencegroup DotProductPrecedence {
    lowerThan: AdditionPrecedence
    higherThan: ComparisonPrecedence
    associativity: left
}

infix operator •: DotProductPrecedence

// Vector class inspired by: https://www.raywenderlich.com/650-overloading-custom-operators-in-swift
struct Vector: Equatable, ExpressibleByArrayLiteral, CustomStringConvertible {
    let x: Double
    let y: Double
    let z: Double

    init(_ cgVector: CGVector) {
        self.x = Double(cgVector.dx)
        self.y = Double(cgVector.dy)
        self.z = 0
    }

    init(_ cgPoint: CGPoint) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
        self.z = 0
    }

    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(arrayLiteral: Double...) {
        assert(arrayLiteral.count == 3, "Must initialize vector with 3 values.")
        self.x = arrayLiteral[0]
        self.y = arrayLiteral[1]
        self.z = arrayLiteral[2]
    }

    init(_ array: [Double]) {
        assert(array.count == 3, "Must initialize vector with 3 values.")
        self.x = array[0]
        self.y = array[1]
        self.z = array[2]
    }

    var description: String {
        return "(\(x), \(y), \(z))"
    }

    var length: Double {
        return sqrt(x*x + y*y + z*z)
    }

    func normalized() -> Vector {
        let length = self.length
        return Vector(x / length, y / length, z / length)
    }

    func rotate(by rotationMatrix: [[Double]]) -> Vector {
        return Vector(
            Vector(rotationMatrix[0]) • self,
            Vector(rotationMatrix[1]) • self,
            Vector(rotationMatrix[2]) • self
        )
    }

    // MARK: Operators
    subscript(index: Int) -> Double {
        get {
            return [x, y, z][index]
        }
    }

    static func *(left: Vector, right: Vector) -> Vector {
        return Vector(
            left.y * right.z - left.z * right.y,
            left.z * right.x - left.x * right.z,
            left.x * right.y - left.y * right.x
        )
    }

    static func •(left: Vector, right: Vector) -> Double {
        return left.x * right.x + left.y * right.y + left.z * right.z
    }

    static func +(left: Vector, right: Vector) -> Vector {
        return Vector(left.x + right.x, left.y + right.y, left.z + right.z)
    }

    static func -(left: Vector, right: Vector) -> Vector {
        return Vector(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    static prefix func -(vector: Vector) -> Vector {
        return Vector(-vector.x, -vector.y, -vector.z)
    }

    static func *(left: Double, right: Vector) -> Vector {
        return Vector(right.x * left, right.y * left, right.z * left)
    }

    static func *(left: Vector, right: Double) -> Vector {
        return right * left
    }

    static func /(left: Vector, right: Double) -> Vector {
        return Vector(left.x / right, left.y / right, left.z / right)
    }

    static func ==(left: Vector, right: Vector) -> Bool {
        return left.x == right.x && left.y == right.y && left.z == right.z
    }
}

struct OrbitalParameters {
    let semiMajorAxis: Double               // a [m]
    let eccentricity: Double                // e [1]
    let argumentOfPeriapsis: Double         // ω [rad]
    let longitudeOfAscendingNode: Double    // Ω [rad] - not needed for a 2D simulation but kept for future-proofing
    let inclination: Double                 // i [rad]
    let meanAnomaly: Double                 // M [rad]

    let standardGravitationalParameter: Double

    //    var timeSincePeriapsis: TimeInterval {
    //        return timeEquation(eccentricAnomaly: self.eccentricAnomaly)
    //    }
    //
    //    var timeToNextPeriapsis: TimeInterval {
    //        return orbitalPeriod - timeSincePeriapsis
    //    }
    //
    //    var radius: Double {
    //        return (semiMajorAxis * (1 - pow(eccentricity, 2))) / (1 + eccentricity * cos(trueAnomaly))
    //    }

    var apoapsis: Double {
        return semiMajorAxis * (1 + eccentricity)
    }

    var periapsis: Double {
        return semiMajorAxis * (1 - eccentricity)
    }

    init(positionVector r: Vector, velocityVector ṙ: Vector, gravitationalConstant μ: Double) {
        // Orbital momentum
        let h = r * ṙ

        // Eccentricity vector
        let e = (ṙ * h / μ) - r / r.length

        // Vector pointing towards the ascending node
        let n = [0, 0, 1] * h

        // True anomaly
        let v: Double
        if r • ṙ >= 0.0 {
            v = acos((e • r) / (e.length * r.length))
        } else {
            v = 2 * Double.pi - acos((e • r) / (e.length * r.length))
        }

        // Orbital inclination
        let i = acos(h.z / h.length)

        // Orbit eccentricity
        let ec = e.length

        // Eccentric anomaly
        let E = 2 * atan(
            tan(v / 2) / sqrt((1 + ec) / (1 - ec))
        )

        // Longitude of the ascending node
        let Ω: Double
        if i == 0.0 || i == Double.pi {
            Ω = 0 // Zero by convention for non-inclined orbits
        } else if n.y >= 0 {
            Ω = acos(n.x / n.length)
        } else {
            Ω = 2 * Double.pi - acos(n.x / n.length)
        }

        // Argument of the periapsis
        let ω: Double
        if ec == 0.0 {
            ω = 0 // Zero for elliptic orbits
        } else if (r * ṙ).z >= 0 {
            ω = atan2(e.y, e.x)
        } else {
            ω = 2 * Double.pi - atan2(e.y, e.x)
        }

        // Mean anomaly
        let M = E - ec * sin(E)

        // Semi-major axis
        let a = 1 / (
            2 / r.length - pow(ṙ.length, 2) / μ
        )

        self.semiMajorAxis = a
        self.eccentricity = ec
        self.argumentOfPeriapsis = ω
        self.longitudeOfAscendingNode = Ω
        self.inclination = i
        self.meanAnomaly = M
        self.standardGravitationalParameter = μ
    }

    var orbitalPeriod: TimeInterval {
        return 2 * Double.pi * sqrt(pow(semiMajorAxis, 3) / standardGravitationalParameter)
    }

    func eccentricAnomaly(after interval: TimeInterval) -> Double {
        // Few redeclarations for readability
        let μ = standardGravitationalParameter
        let e = eccentricity
        let M0 = meanAnomaly

        // Mean anomaly after interval
        let M: Double
        if interval == 0 {
            M = M0
        } else {
            M = M0 + interval * sqrt(μ / pow(semiMajorAxis, 3))
        }

        // Solve for eccentric anomaly E(t) with Newton-Raphson method
        var E = M
        while true {
            let dE = (E - e * sin(E) - M) / (1 - e * cos(E))
            E -= dE
            if abs(dE) < 1e-6 { break }
        }

        return E
    }

    func cartesianState(atAnomaly eccentricAnomaly: Double) -> (position: Vector, velocity: Vector) {
        // Few redeclarations for readability
        let a = semiMajorAxis
        let e = eccentricity
        let μ = standardGravitationalParameter
        let i = inclination
        let ω = argumentOfPeriapsis
        let Ω = longitudeOfAscendingNode

        // Eccentric anomaly
        let E = eccentricAnomaly

        // True anomaly
        let v = 2 * atan2(
            sqrt(1 + e) * sin(E / 2),
            sqrt(1 - e) * cos(E / 2)
        )

        // Distance to central body
        let rc = a * (1 - e * cos(E))

        // Position vector
        let o = rc * Vector(cos(v), sin(v), 0)

        // Velocity vector
        let ȯ = (sqrt(μ * a) / rc) * Vector(-sin(E), sqrt(1 - pow(e, 2)) * cos(E), 0)

        // Rotate position and velocity vectors
        func rotate(vector v: Vector) -> Vector {
            return Vector(
                v.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - v.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
                v.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + v.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
                v.x * (sin(ω) * sin(i)) + v.y * (cos(ω) * sin(i))
            )
        }

        let r = rotate(vector: o)
        let ṙ = rotate(vector: ȯ)

        // Return the cartesian state vectors
        return (position: r, velocity: ṙ)
    }

    func cartesianState(after interval: TimeInterval) -> (position: Vector, velocity: Vector) {
        return cartesianState(atAnomaly: eccentricAnomaly(after: interval))
    }

    func orbitPath() -> CGPath {
        let stepSize = 0.01
        var eccentricAnomaly = 0.0
        var points: [CGPoint] = []

        while eccentricAnomaly < 2 * Double.pi {
            let (position, _) = cartesianState(atAnomaly: eccentricAnomaly)
            points.append(CGPoint(x: position.x, y: position.y))

            eccentricAnomaly += stepSize
        }

        let path = CGMutablePath()
        path.addLines(between: points)

        return path
    }
}

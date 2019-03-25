//
//  Vector.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
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
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat

    init(_ cgVector: CGVector) {
        self.x = cgVector.dx
        self.y = cgVector.dy
        self.z = 0
    }

    init(_ cgPoint: CGPoint) {
        self.x = cgPoint.x
        self.y = cgPoint.y
        self.z = 0
    }

    init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(arrayLiteral: CGFloat...) {
        assert(arrayLiteral.count == 3, "Must initialize vector with 3 values.")
        self.x = arrayLiteral[0]
        self.y = arrayLiteral[1]
        self.z = arrayLiteral[2]
    }

    init(_ array: [CGFloat]) {
        assert(array.count == 3, "Must initialize vector with 3 values.")
        self.x = array[0]
        self.y = array[1]
        self.z = array[2]
    }

    var description: String {
        return "(\(x), \(y), \(z))"
    }

    var length: CGFloat {
        return sqrt(x*x + y*y + z*z)
    }

    var cgVector: CGVector { return CGVector(dx: self.x, dy: self.y) }
    var cgPoint: CGPoint { return CGPoint(x: self.x, y: self.y) }

    func normalized() -> Vector {
        let length = self.length
        return Vector(x / length, y / length, z / length)
    }

    func rotate(by rotationMatrix: [[CGFloat]]) -> Vector {
        return Vector(
            Vector(rotationMatrix[0]) • self,
            Vector(rotationMatrix[1]) • self,
            Vector(rotationMatrix[2]) • self
        )
    }

    // MARK: Operators
    subscript(index: Int) -> CGFloat {
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

    static func •(left: Vector, right: Vector) -> CGFloat {
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

    static func *(left: CGFloat, right: Vector) -> Vector {
        return Vector(right.x * left, right.y * left, right.z * left)
    }

    static func *(left: Vector, right: CGFloat) -> Vector {
        return right * left
    }

    static func /(left: Vector, right: CGFloat) -> Vector {
        return Vector(left.x / right, left.y / right, left.z / right)
    }

    static func ==(left: Vector, right: Vector) -> Bool {
        return left.x == right.x && left.y == right.y && left.z == right.z
    }
}

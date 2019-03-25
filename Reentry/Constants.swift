//
//  Constants.swift
//  DragTests
//
//  Created by Til Blechschmidt on 22.03.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreGraphics
import SpriteKit

// Values roughly resemble real world earth
struct Planet {
    static let radius: CGFloat           = 6.3781 * pow(10.0, 6.0)      // [m]
    static let mass: CGFloat             = 5.9722 * pow(10.0, 24.0)     // [kg]
    static let atmosphereHeight: CGFloat = 100000                       // [m]
    static let gravitationalAcc: CGFloat = 9.80665                      // [m/s^2]
    static let atmosphereDensity: CGFloat = 1.2250                      // [Pa]
}

// Roughly resembles a SpaceX Dragon capsule
struct Capsule {
    static let size = CGSize(width: 3.7, height: 6.1)
    static let mass: CGFloat = 6400     // [kg]
    static let thrust: CGFloat = 934000 // [N]
    static let secondsOfThrust: TimeInterval = 10
    static let heatDissapationPerSecond: CGFloat = 10
    static let heatShieldCapacity: CGFloat = 200000
    static let heatLimit: CGFloat = 15000
}

struct Simulation {
    static let scale: CGFloat = 0.000003
    static let gravitationalConstant: CGFloat = 6.674 * pow(10.0, -11.0)
    static let molarMassOfAir: CGFloat = 0.0289644
    static let universalGasConstant: CGFloat = 8.31432
    static let averageAirTemperature: CGFloat = 250.0 // [K]
}

struct Camera {
    static let defaultScale: CGFloat = 40000
}

struct Emitter {
    static let deorbit = "DeorbitParticles.sks"
    static let menu = "MenuParticles.sks"
    static let stars = "Stars.sks"
    static let thruster = "ThrusterParticles.sks"
}

struct Game {
    static let settlingVelocityThreshold: CGFloat = 5 // Speed at which the capsule is considered landed [m/s]
    static let landingSpotScore: CGFloat = 10000 // Value added to score if you land spot-on
    static let remainingFuelScore: CGFloat = 2000 // Value added to score if your fuel is full
    static let maximumAcceleration: CGFloat = 150 // Maximum tolerated acceleration [m/s^2]
}

struct Layer {
    static let ui: CGFloat = 100
    static let entity: CGFloat = 4
    static let atmosphere: CGFloat = 1
    static let particles: CGFloat = 3
    static let target: CGFloat = 2
}

struct Shader {
    static let stroked = SKShader(source: "void main() {" +
        "int stripe = int(u_path_length) / 5000;" +
        "int h = int(v_path_distance) / stripe % 2;" +
        "vec4 color = v_color_mix;" +
        "gl_FragColor = color * h;" +
    "}")
}

//: # Reentry
//: This playground is a game that simulates atmospheric reentry of a space capsule!
//: Land as close as possible to the marked location on the planet to get a high score.
//: Watch out that you don't kill your crew by:
//:   - Crushing them by decelerating too fast
//:   - Running out of fuel and getting stranded in orbit
//:   - Getting evaporated in the atmosphere
//:
//: ## Time warp
//: Since space is vast this game contains a time warp mechanic. There is physics and rails warp where the physics warp allows you to still boost/break while rails warp is faster but disables most physics calculations and prevents the engine from being fired. For that reason the latter is only allowed outside the atmosphere (which is below 100km).
//:
//:
//: ## Rocket science in a nutshell
//: The line around the planet is your current trajectory. In order to change it you have to ignite your rocket thrusters.
//: The orbit has two relevant features:
//:   - **Apoapsis** _Highest point_
//:   - **Periapsis** _Lowest point_
//:
//:
//: Burning prograde (accelerating) will raise your orbit height at the opposite side while thrusting retrograde (breaking) will lower it.
//:
//:
//: # Quick start guide
//: Turn the capsule to point in the opposite direction of your movement and press the `ignite engine` button until your `Periapsis` goes below 80km. Then wait until it reaches the atmosphere (indicated by the dashed line) and make sure it goes heatshield first.
//:

import PlaygroundSupport
import SpriteKit

// Load the SKScene from 'GameScene.sks'
let frame = CGRect(x:0 , y:0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
let sceneView = SKView(frame: frame)
let scene = MenuScene(size: sceneView.bounds.size)
scene.scaleMode = .aspectFill
sceneView.presentScene(scene)

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView

#if !targetEnvironment(simulator)
PlaygroundSupport.PlaygroundPage.current.wantsFullScreenLiveView = true
#endif

/*
* Copyright (c) 2015 Droids on Roids LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import CoreMotion
import SpriteKit

struct Collision {
    static let Ball: UInt32 = 0x1 << 0       // bin(001) = dec(1)
    static let BlackHole: UInt32 = 0x1 << 1  // bin(010) = dec(2)
    static let FinishHole: UInt32 = 0x1 << 2 // bin(100) = dec(4)
}

class GameScene: SKScene {
    var manager: CMMotionManager?
    var ball: SKSpriteNode!
    
    var timer: NSTimer?
    var seconds: Double?
    
    // MARK: - SpriteKit Methods
    
    override func didMoveToView(view: SKView) {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "increaseTimer", userInfo: nil, repeats: true)
        
        physicsWorld.contactDelegate = self
        
        ball = SKSpriteNode(imageNamed: "Ball")
        ball.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        ball.physicsBody = SKPhysicsBody(circleOfRadius: CGRectGetHeight(ball.frame) / 2.0)
        ball.physicsBody?.mass = 4.5
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.dynamic = true // necessary to detect collision
        ball.physicsBody?.categoryBitMask = Collision.Ball
        ball.physicsBody?.collisionBitMask = Collision.Ball
        ball.physicsBody?.contactTestBitMask = Collision.BlackHole | Collision.FinishHole
        ball.physicsBody?.affectedByGravity = false
        addChild(ball)
        
        manager = CMMotionManager()
        if let manager = manager where manager.deviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.01
            manager.startDeviceMotionUpdates()
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        if let gravityX = manager?.deviceMotion?.gravity.x, gravityY = manager?.deviceMotion?.gravity.y where ball != nil {
            // let newPosition = CGPoint(x: Double(ball.position.x) + gravityX * 35.0, y: Double(ball.position.y) + gravityY * 35.0)
            // let moveAction = SKAction.moveTo(newPosition, duration: 0.0)
            // ball.runAction(moveAction)
            
            // applyImpulse() is much better than applyForce()
            // ball.physicsBody?.applyForce(CGVector(dx: CGFloat(gravityX) * 5000.0, dy: CGFloat(gravityY) * 5000.0))
            
            ball.physicsBody?.applyImpulse(CGVector(dx: CGFloat(gravityX) * 200.0, dy: CGFloat(gravityY) * 200.0))
        }
    }
    
    // MARK: - Ball Methods
    
    func centerBall() {
        ball.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        let moveAction = SKAction.moveTo(CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame)), duration: 0.0)
        ball.runAction(moveAction)
    }
    
    func alertWon() {
        let alertController = UIAlertController(title: "You've won", message: String(format: "It took you %.1f seconds", arguments: [seconds!]), preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default) { (action) -> Void in
            self.resetTimer()
            self.centerBall()
        }
        alertController.addAction(okAction)
        if let rootViewController = view?.window?.rootViewController {
            rootViewController.presentViewController(alertController, animated: true, completion: { () -> Void in
                self.centerBall()
            })
        }
    }
    
    // MARK: - Timer Methods
    
    func increaseTimer() {
        seconds = (seconds ?? 0.0) + 0.01
    }
    
    func resetTimer() {
        seconds = 0.0
    }
}

// MARK: - SKPhysicsContact Delegate Methods
extension GameScene: SKPhysicsContactDelegate {
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == Collision.BlackHole || contact.bodyB.categoryBitMask == Collision.BlackHole {
            centerBall()
            resetTimer()
        } else if contact.bodyA.categoryBitMask == Collision.FinishHole || contact.bodyB.categoryBitMask == Collision.FinishHole {
            alertWon()
        }
    }
}

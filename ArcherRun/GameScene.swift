//
//  GameScene.swift
//  SpriteKitBasics
//
//  Created by Eduardo Dalencon on 21/09/23.
//

import SpriteKit

struct PhysicsCategory {
    static let character: UInt32 = 0x1 << 0
    static let enemy: UInt32 = 0x1 << 1
    static let bullet: UInt32 = 0x1 << 2
    static let ground: UInt32 = 0x1 << 3
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    var score = 0
    let character = SKSpriteNode(imageNamed: "Char")
    let ground = SKSpriteNode(imageNamed: "Ground")
    
    let jumpButton = SKSpriteNode(imageNamed: "Jump")
    let leftButton = SKSpriteNode(imageNamed: "Left")
    let rightButton = SKSpriteNode(imageNamed: "Right")
    let fireButton = SKSpriteNode(imageNamed: "Fire")

    var isLeftButtonPressed = false
    var isRightButtonPressed = false
    
    var isCharacterFacingRight = true
    var isCharacterJumping = false
    
    var joystick: Joystick = Joystick()

    override func didMove(to view: SKView) {

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        
        //Score
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: 0, y: 160)
        addChild(scoreLabel)
        
        // Personagem
        character.position = CGPoint(x: 0, y: 100)
        character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        character.physicsBody?.categoryBitMask = PhysicsCategory.character
        character.physicsBody?.collisionBitMask = PhysicsCategory.ground
        character.physicsBody?.contactTestBitMask = PhysicsCategory.bullet
        character.physicsBody?.affectedByGravity = true
        character.physicsBody?.allowsRotation = false
        addChild(character)
        
        //Chão
        ground.position = CGPoint(x: 0, y: -170)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.zPosition = -2
        addChild(ground)
        
//        leftButton.position = CGPoint(x: -340, y: -130)
//        addChild(leftButton)
//
//        rightButton.position = CGPoint(x: -240, y: -130)
//        addChild(rightButton)
       
        jumpButton.position = CGPoint(x: 340, y: -130)
        addChild(jumpButton)
     
        fireButton.position = CGPoint(x: 240, y: -130)
        addChild(fireButton)
        
        //joystick
        joystick.position = CGPoint(x: -290, y: -130)
        self.addChild(joystick)
        
        
        
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnEnemy()
        }
        let waitAction = SKAction.wait(forDuration: 2.0)
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)

        run(repeatAction)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if leftButton.contains(location) {
                isLeftButtonPressed = true
            } else if rightButton.contains(location) {
                isRightButtonPressed = true
            } else if jumpButton.contains(location) && !isCharacterJumping {
                jumpCharacter()
            } else if fireButton.contains(location) {
                fireBullet()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if leftButton.contains(location) {
                isLeftButtonPressed = false
            } else if rightButton.contains(location) {
                isRightButtonPressed = false
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if isLeftButtonPressed {
            moveCharacterLeft()
        } else if isRightButtonPressed {
            moveCharacterRight()
        }
        
        if character.physicsBody?.allContactedBodies().contains(ground.physicsBody!) ?? false {
            isCharacterJumping = false
        }
        
        //joystick
        
        if joystick.velocity.x != 0 || joystick.velocity.y != 0 {
                  character.position = CGPointMake(character.position.x + 0.1 * joystick.velocity.x, character.position.y + 0.1 * joystick.velocity.y)
            }
    }

    func moveCharacterLeft() {
        var newX = character.position.x - 5.0
        if (newX < -350){
            newX = -350
        }
        character.position.x = newX
        
        if isCharacterFacingRight {
            character.xScale = -1.0
            isCharacterFacingRight = false
        }
    }

    func moveCharacterRight() {
        var newX = character.position.x + 5.0
        if (newX > 350){
            newX = 350
        }
        character.position.x = newX
        
        if !isCharacterFacingRight {
            character.xScale = 1.0
            isCharacterFacingRight = true
        }
    }
    
    func jumpCharacter() {
        let jumpForce = CGVector(dx: 0.0, dy: 9000.0)
        character.physicsBody?.applyForce(jumpForce)
        print("jump")
        isCharacterJumping = true
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "Button")
        let xOffset: CGFloat = isCharacterFacingRight ? 20.0 : -20.0
           bullet.position = CGPoint(x: character.position.x + xOffset, y: character.position.y)

       
        let bulletSpeed: CGFloat = 2000.0
        let direction = isCharacterFacingRight ? 1.0 : -1.0
        let bulletVelocity = CGVector(dx: bulletSpeed * direction, dy: 0)

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.enemy

        addChild(bullet)

        bullet.physicsBody?.velocity = bulletVelocity
    }
    
    func spawnEnemy() {
      
        let minDistanceToCharacter: CGFloat = 30.0

        var enemyPosition = randomSpawnPosition()
        var distanceToCharacter = abs(character.position.x - enemyPosition.x)

        while distanceToCharacter < minDistanceToCharacter {
            enemyPosition = randomSpawnPosition()
            distanceToCharacter = abs(character.position.x - enemyPosition.x)
        }

        let enemy = SKSpriteNode(imageNamed: "Enemy")
        enemy.zPosition = -1
        enemy.position = enemyPosition
        addChild(enemy)

        let randomMoveX = CGFloat.random(in: -100.0...100.0)
        let randomMoveY = CGFloat.random(in: -100.0...100.0)
        let moveAction = SKAction.moveBy(x: randomMoveX, y: randomMoveY, duration: 2.0)
        enemy.run(SKAction.repeatForever(moveAction))

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.bullet
    }

    
    func randomSpawnPosition() -> CGPoint {
        let minX: CGFloat = -200.0
        let maxX: CGFloat = 200.0
        let minY: CGFloat = -100.0
        let maxY: CGFloat = 100.0

        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)

        return CGPoint(x: randomX, y: randomY)
    }
    
    func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if (contact.bodyA.categoryBitMask == PhysicsCategory.bullet && contact.bodyB.categoryBitMask == PhysicsCategory.enemy) ||
           (contact.bodyA.categoryBitMask == PhysicsCategory.enemy && contact.bodyB.categoryBitMask == PhysicsCategory.bullet) {
            
            score += 1
            updateScoreLabel()
            
            if let bulletNode = contact.bodyA.node {
                bulletNode.removeFromParent()
            }
            if let enemyNode = contact.bodyB.node {
                enemyNode.removeFromParent()
            }
        }
    }

}

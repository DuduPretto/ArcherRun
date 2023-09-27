import SpriteKit

struct PhysicsCategory {
    static let character: UInt32 = 0x1 << 0
    static let enemy: UInt32 = 0x1 << 1
    static let bullet: UInt32 = 0x1 << 2
    static let ground: UInt32 = 0x1 << 3
}

class GameScene: SKScene, SKPhysicsContactDelegate, FireBowDelegate {
    var lastJumpTime: TimeInterval = 0.0
    let jumpCooldown: TimeInterval = 0.5
    
    var score = 0
    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    let character = SKSpriteNode(imageNamed: "CharacterWalk1")
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
    var bowJoystick: BowJoystick = BowJoystick()
    
    let cam = SKCameraNode()
    
    var aimLine = [SKShapeNode]()
    
//    let frames:[SKTexture] = createTexture("Character")
    
    func isCharacterTouchingMask(mask: UInt32) -> Bool {
        // Get all bodies in contact with the character
        let contactedBodies = character.physicsBody?.allContactedBodies() ?? []

        // Check if any of the contacted bodies have the specified collision mask
        for contactedBody in contactedBodies {
            if contactedBody.categoryBitMask == mask {
                return true
            }
        }

        return false
    }

    override func didMove(to view: SKView) {
        self.bowJoystick.delegate = self
        
        //BackGroudMusic
        ArcherRunPlayerStats.shared.setSounds(true)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        self.camera = cam
        addChild(cam)
        cam.zPosition = 5
        
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
        
        leftButton.position = CGPoint(x: -340, y: -130)
        leftButton.zPosition = 100
        cam.addChild(leftButton)

        rightButton.position = CGPoint(x: -240, y: -130)
        cam.addChild(rightButton)
       
        jumpButton.position = CGPoint(x: 340, y: -130)
        cam.addChild(jumpButton)

        //bow joystick
        bowJoystick.position = CGPoint(x: 240, y: -110)
        cam.addChild(bowJoystick)
        
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
            let locationInCam = convert(location, to: cam)

            if leftButton.contains(locationInCam) {
                isLeftButtonPressed = true
                startAnimationLeft()
            } else if rightButton.contains(locationInCam) {
                isRightButtonPressed = true
                startAnimationRight()
            } else if jumpButton.contains(locationInCam) && !isCharacterJumping {
                jumpCharacter()
            } else if fireButton.contains(locationInCam) {
                fireBullet()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let locationInCam = convert(location, to: cam)
//            self.run(SoundFileName.TapFile.rawValue, onNode: self)

            if leftButton.contains(locationInCam) {
                isLeftButtonPressed = false
            } else if rightButton.contains(locationInCam) {
                isRightButtonPressed = false
            }
            stopAnimation()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        
        cam.position = character.position
        
        leftButton.position = CGPoint(x: -340, y: -130)
           rightButton.position = CGPoint(x: -240, y: -130)
           jumpButton.position = CGPoint(x: 340, y: -130)
           fireButton.position = CGPoint(x: 240, y: -130)

       if isLeftButtonPressed {
           moveCharacterLeft()
       } else if isRightButtonPressed {
           moveCharacterRight()
       }

        let isTouchingMask = isCharacterTouchingMask(mask: 4294967295)
        if isTouchingMask {
            isCharacterJumping = false
        }
        
        character.position = CGPointMake(character.position.x + 0.1 * joystick.velocity.x, character.position.y)
    }
    
    func createTexture(_ name: String) -> [SKTexture] {
        let textureAtlas = SKTextureAtlas(named: name)
            var frames = [SKTexture]()
            for i in 0...textureAtlas.textureNames.count - 1{
                frames.append(textureAtlas.textureNamed(textureAtlas.textureNames[i]))
            }
            return frames
    }

    func moveCharacterLeft() {
        let newX = character.position.x - 7.0
       
        character.position.x = newX

        if isCharacterFacingRight {
            character.xScale = -1.0
            isCharacterFacingRight = false
        }
    }

    func moveCharacterRight() {
        let newX = character.position.x + 7.0
        
        character.position.x = newX

        if !isCharacterFacingRight {
            character.xScale = 1.0
            isCharacterFacingRight = true
        }
    }
    
    func jumpCharacter() {
        let currentTime = CACurrentMediaTime()
        
        // Check if enough time has passed since the last jump
        if currentTime - lastJumpTime >= jumpCooldown {
            let jumpForce = CGVector(dx: 0.0, dy: 9000.0)
            character.physicsBody?.applyForce(jumpForce)
            print("jump")
            isCharacterJumping = true
            // Update the last jump time
            lastJumpTime = currentTime
        }
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
        
    func run(_ fileName: String, onNode: SKNode) {
        if ArcherRunPlayerStats.shared.getSound(){
            onNode.run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))

        }
    }

    func fireBow(vector: CGPoint) {
        
        let bullet = SKSpriteNode(imageNamed: "Button")
        let xOffset: CGFloat = isCharacterFacingRight ? 20.0 : -20.0
           bullet.position = CGPoint(x: character.position.x + xOffset, y: character.position.y)

       
        let bulletSpeed: CGFloat = 15
        let bulletVelocity = CGVector(dx: bulletSpeed * -vector.x, dy: bulletSpeed * -vector.y)

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.enemy

        addChild(bullet)

        bullet.physicsBody?.velocity = bulletVelocity
        
        self.run(SKAction.wait(forDuration: 2)) {
            bullet.removeFromParent()
        }
    }
 
    
    func drawDottetLine(initialVelocityPoint: CGPoint, gravity: CGFloat = 6.8) {
        for dot in aimLine{
            dot.removeFromParent()
        }
        let dotSpacing: CGFloat = 10
        let scene = self
        // Create and add dots along the trajectory
        var currentPosition = CGPoint.zero
        var currentVelocity = CGPoint(x: initialVelocityPoint.x * 1, y: initialVelocityPoint.y * 1)
        
        // Calculate the time it takes to reach the next dot's position
        let totalTime = currentVelocity.y / gravity
        let timeToNextDot = totalTime / dotSpacing
        
        while currentPosition.y >= 0 {
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor = SKColor.blue
            dot.name = "dot"
            dot.position = CGPoint(x: currentPosition.x + character.position.x, y: currentPosition.y + character.position.y)
            scene.addChild(dot)
            aimLine.append(dot)
            
            // Update the position and velocity for the next dot
            currentPosition.x += currentVelocity.x * timeToNextDot
            currentPosition.y += currentVelocity.y * timeToNextDot - 0.5 * gravity * (timeToNextDot * timeToNextDot)
            currentVelocity.y -= gravity * timeToNextDot
            scene.run(SKAction.wait(forDuration: 1)) {
                dot.removeFromParent()
            }
        }
    }
}

// Joystick
extension GameScene {
    
//   movement joystick
//   joystick.position = CGPoint(x: -290, y: -110)
//   cam.addChild(joystick)
    
//    func joystickActions() {
//         if joystick.velocity.x != 0 {
//             character.position = CGPointMake(character.position.x + 0.1 * joystick.velocity.x, character.position.y)
//             if joystick.velocity.x > 0 {
//                 let frames:[SKTexture] = createTexture("Character")
//                 character.run(SKAction.repeat(SKAction.animate(with: frames,
//                                                                        timePerFrame: TimeInterval(0.1),
//                                                                        resize: false, restore: false), count: 1))
//                
//                 isCharacterFacingRight = true
//                 character.xScale = 1.0
//                 print (joystick.velocity.y)
//             } else {
//                 let frames:[SKTexture] = createTexture("Character")
//                 character.run(SKAction.repeat(SKAction.animate(with: frames,
//                                                                        timePerFrame: TimeInterval(0.1),
//                                                                        resize: false, restore: false), count: 1))
//                 character.xScale = -1.0
//                 isCharacterFacingRight = false
//             }
//         }
//         if joystick.velocity.y > 50 && !isCharacterJumping{
//             jumpCharacter()
//         }
//     }
}

// Animation
extension GameScene {
    func startAnimationLeft() {
        let frames:[SKTexture] = createTexture("CharacterWalk")
        character.run(SKAction.repeatForever(SKAction.animate(with: frames,
                                                               timePerFrame: TimeInterval(0.15),
                                                               resize: true, restore: false)))
        character.xScale = -1.0
        isCharacterFacingRight = false
    }
    
    func startAnimationRight() {
        let frames:[SKTexture] = createTexture("CharacterWalk")
        isCharacterFacingRight = true
        character.xScale = 1.0
        character.run(SKAction.repeatForever(SKAction.animate(with: frames,
                                                                   timePerFrame: TimeInterval(0.15),
                                                                   resize: true, restore: false)))
    }
    
    func stopAnimation() {
        character.removeAllActions()
    }
}

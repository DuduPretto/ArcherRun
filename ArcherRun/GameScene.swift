import SpriteKit

struct PhysicsCategory {
    static let character: UInt32 = 0x1 << 0
    static let enemy: UInt32 = 0x1 << 1
    static let bullet: UInt32 = 0x1 << 2
    static let ground: UInt32 = 0x1 << 3
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    var lastJumpTime: TimeInterval = 0.0
    let jumpCooldown: TimeInterval = 0.5
    
    var score = 0
    let scoreLabel = SKLabelNode(fontNamed: "Arial")
    let lifeLabel = SKLabelNode(fontNamed: "Arial")
    let character = SKSpriteNode(imageNamed: "CharacterWalk1")
    let ground = SKSpriteNode(imageNamed: "Ground")
    let jumpButton = SKSpriteNode(imageNamed: "Jump")
    let leftButton = SKSpriteNode(imageNamed: "Left")
    let rightButton = SKSpriteNode(imageNamed: "Right")
    let fireButton = SKSpriteNode(imageNamed: "Fire")
    let background = SKSpriteNode(imageNamed: "bg-front")

    var isLeftButtonPressed = false
    var isRightButtonPressed = false
    
    var isCharacterFacingRight = true
    var isCharacterJumping = false
    
    var joystick: Joystick = Joystick()
    var bowJoystick: BowJoystick = BowJoystick()
    
    let cam = SKCameraNode()
    
    var aimLine = [SKShapeNode]()
    
    var enemies: [Enemy] = []
    let enemySpawnRate: TimeInterval = 2.0
    var lastSpawnTime: TimeInterval = 0.0
    var isShooting: Bool = false
    
    var characterLife = 3
    
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
    
    func isBulletTouchingMask(mask: UInt32, node: SKSpriteNode) -> Bool {
        
        let contactedBodies = node.physicsBody?.allContactedBodies() ?? []

        for contactedBody in contactedBodies {
            if contactedBody.categoryBitMask == mask {
                return true
            }
        }

        return false
    }

    override func didMove(to view: SKView) {
        
        
        // Create the background node
         
            background.zPosition = -10
            background.position = CGPoint(x: 0, y: 0) // Center the background
            background.size = frame.size
            addChild(background)
        
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
        cam.addChild(scoreLabel)
        
        //Life
        lifeLabel.text = "Lives: \(characterLife)"
        lifeLabel.fontSize = 24
        lifeLabel.position = CGPoint(x: 300, y: 160)
        cam.addChild(lifeLabel)
        
        // Personagem
        character.position = CGPoint(x: 0, y: 100)
        character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        character.physicsBody?.categoryBitMask = PhysicsCategory.character
        character.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.enemy
        character.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        character.physicsBody?.affectedByGravity = true
        character.physicsBody?.allowsRotation = false
        addChild(character)
        
        //Chão
//        ground.position = CGPoint(x: 0, y: -170)
//        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
//        ground.physicsBody?.isDynamic = false
//        ground.zPosition = -2
//        addChild(ground)
        
        leftButton.position = CGPoint(x: -340, y: -130)
        leftButton.zPosition = 100
        leftButton.size = CGSize(width: 80, height: 60)
        cam.addChild(leftButton)

        rightButton.position = CGPoint(x: -240, y: -130)
        rightButton.size = CGSize(width: 80, height: 60)
        cam.addChild(rightButton)
       
        jumpButton.position = CGPoint(x: 340, y: -20)
        jumpButton.size = CGSize(width: 60, height: 80)
        cam.addChild(jumpButton)

        //bow joystick
        bowJoystick.position = CGPoint(x: 240, y: -110)
        cam.addChild(bowJoystick)
        
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnEnemyy()
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
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let locationInCam = convert(location, to: cam)

            if !leftButton.contains(locationInCam) {
                isLeftButtonPressed = false
                
            }
            
            if !rightButton.contains(locationInCam) {
                isRightButtonPressed = false
               
            }
        }
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let locationInCam = convert(location, to: cam)
            
            if leftButton.contains(locationInCam) {
                isLeftButtonPressed = false
                character.physicsBody?.velocity.dx = 0
            } else if rightButton.contains(locationInCam) {
                isRightButtonPressed = false
                character.physicsBody?.velocity.dx = 0
            }
            stopAnimation()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        
        cam.position = character.position
        
        background.position = cam.position
        
        leftButton.position = CGPoint(x: -340, y: -130)
        rightButton.position = CGPoint(x: -240, y: -130)
        jumpButton.position = CGPoint(x: 340, y: -20)
        fireButton.position = CGPoint(x: 240, y: -130)

        if !isShooting {
            if isLeftButtonPressed {
                moveCharacterLeft()
            } else if isRightButtonPressed {
                moveCharacterRight()
            }
        } else {
            startAnimationShot()
        }
       
        let isTouchingMask = isCharacterTouchingMask(mask: 4294967295)
        if isTouchingMask {
            isCharacterJumping = false
        }
        
        updateEnemyAI()
        
        character.position = CGPointMake(character.position.x + 0.1 * joystick.velocity.x, character.position.y)
        
        if bowJoystick.velocity.x > 0 {
            character.xScale = -1.0
        } else if bowJoystick.velocity.x < 0 {
            character.xScale = 1.0
        }
        
        for node in self.children {
            if let arrowNode = node as? SKSpriteNode, arrowNode.name == "bullet" {
                print("rodando")
                updateArrowRotation(for: arrowNode)
                
                let isTouchingMask = isBulletTouchingMask(mask: 4294967295, node: arrowNode)
                if isTouchingMask {
                    arrowNode.removeFromParent()
                }
            }
        }
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
        let moveSpeed: CGFloat = 300.0
        character.physicsBody?.velocity.dx = -moveSpeed

        if isCharacterFacingRight {
            character.xScale = -1.0
            isCharacterFacingRight = false
        }
    }

    func moveCharacterRight() {
        let moveSpeed: CGFloat = 300.0
        character.physicsBody?.velocity.dx = moveSpeed

        if !isCharacterFacingRight {
            character.xScale = 1.0
            isCharacterFacingRight = true
        }
    }
    
    func jumpCharacter() {
        let currentTime = CACurrentMediaTime()
        
        // Check if enough time has passed since the last jump
        if currentTime - lastJumpTime >= jumpCooldown {
            let jumpForce = CGVector(dx: 0.0, dy: 4000.0)
            character.physicsBody?.applyForce(jumpForce)
            isCharacterJumping = true
            // Update the last jump time
            lastJumpTime = currentTime
            
            if isLeftButtonPressed || isRightButtonPressed {
                stopAnimation()
            }
        }
    }

    func toogleShot() {
        if isShooting == true {
            self.run(SoundFileName.bowShot.rawValue, onNode: self)
            stopAnimationShot()
        }
        
        isShooting.toggle()
    }

    
    func randomSpawnPosition() -> CGPoint {
        let minX: CGFloat = -200.0
        let maxX: CGFloat = 2000.0
        let minY: CGFloat = -100.0
        let maxY: CGFloat = 1000.0

        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)

        return CGPoint(x: randomX, y: randomY)
    }
    
    func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }
    
    func updateLifeLabel() {
        lifeLabel.text = "Lives: \(characterLife)"
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
                self.run(SoundFileName.hurtMamute.rawValue, onNode: self)
            }
        }
        
        if (contact.bodyA.categoryBitMask == PhysicsCategory.character && contact.bodyB.categoryBitMask == PhysicsCategory.enemy) ||
            (contact.bodyA.categoryBitMask == PhysicsCategory.enemy && contact.bodyB.categoryBitMask == PhysicsCategory.character) {
            
            // Reduce character's life
            characterLife -= 1
            self.run(SoundFileName.hurtMan.rawValue, onNode: self)
            updateLifeLabel()
            
            if(contact.bodyA.categoryBitMask == PhysicsCategory.character){
                
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }
            
        
            print("hit")
                
                // Check if character has run out of life
                if characterLife <= 0 {
                    // Character has no life left, handle game over logic here
                    gameOver()
                }
            }
    }
    
    func gameOver() {
        // Display a game over message or perform other actions
        print("Game Over")
        
        let menu = MainMenu()
        menu.menu()
        
        // Reset the score and character life
        score = 0
        characterLife = 3
        updateScoreLabel()
        updateLifeLabel()
        
    }
        
    func run(_ fileName: String, onNode: SKNode) {
        if ArcherRunPlayerStats.shared.getSound(){
            onNode.run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
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
        character.xScale = 1.0
        character.run(SKAction.repeatForever(SKAction.animate(with: frames,
                                                                   timePerFrame: TimeInterval(0.15),
                                                                   resize: true, restore: false)))
        isCharacterFacingRight = true
    }
    
    func stopAnimation() {
        character.removeAllActions()
    }
    
    func startAnimationShot() {
        let frames:[SKTexture] = createTexture("BowShot")
        character.run(SKAction.repeatForever(SKAction.animate(with: frames,
                                                                   timePerFrame: TimeInterval(0.15),
                                                                   resize: true, restore: false)))
    }
    
    func stopAnimationShot() {
        let frames:[SKTexture] = createTexture("BowNoShot")
        character.run(SKAction.repeatForever(SKAction.animate(with: frames,
                                                                   timePerFrame: TimeInterval(0.15),
                                                                   resize: true, restore: false)))
    }
    
    func spawnEnemyy() {
            let currentTime = CACurrentMediaTime()

            if currentTime - lastSpawnTime >= enemySpawnRate {
                lastSpawnTime = currentTime

                let enemy = Enemy(target: character)
                enemy.position = randomSpawnPosition()
                let frames:[SKTexture] = createTexture("Mamutes")
                enemy.run(SKAction.repeatForever(SKAction.animate(with: frames,
                                                                           timePerFrame: TimeInterval(0.15),
                                                                           resize: true, restore: false)))
                
                addChild(enemy)
                enemies.append(enemy)
//                self.run(SKAction.wait(forDuration: 5)){
//                    self.run(SoundFileName.soundMamute.rawValue, onNode: self)
//                }
            }
        }

        func updateEnemyAI() {
            for enemy in enemies {
                enemy.update()
            }
        }
    
    func updateArrowRotation(for arrow: SKSpriteNode) {
        let angle = atan2(arrow.physicsBody!.velocity.dy, arrow.physicsBody!.velocity.dx)
        
        var degrees = angle + CGFloat( .pi / 180.0)
        
        if arrow.physicsBody!.velocity.dx < 0 {
                degrees += 270.0
            }

        arrow.zRotation = degrees
    }
}

class Enemy: SKSpriteNode {
    var target: SKSpriteNode?
    var speeed: CGFloat = 100.0 // Adjust the speed as needed
    var isJumping = false
    var lastDirectionChangeTime: TimeInterval = 0.0
    let directionChangeCooldown: TimeInterval = 0.2 // Set the cooldown time to 2 seconds

    init(target: SKSpriteNode) {
        self.target = target
        let texture = SKTexture(imageNamed: "StandartMamute")
        super.init(texture: texture, color: .clear, size: texture.size())
        configurePhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configurePhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask = PhysicsCategory.character | PhysicsCategory.ground
        physicsBody?.contactTestBitMask = PhysicsCategory.character
        physicsBody?.affectedByGravity = true
        physicsBody?.allowsRotation = false
    }

    func update() {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastDirectionChangeTime < directionChangeCooldown{
            return
        }
        lastDirectionChangeTime = currentTime
            if let target = target {
                // Calculate vector towards the target (seek behavior)
                let dx = target.position.x - position.x
//                let moveSpeed: CGFloat = 100.0
                
                if(abs(dx) < 600){
                    let moveSpeed: CGFloat = 100.0
                    if dx > 0 {
                        physicsBody?.velocity.dx = moveSpeed
                        self.xScale = -1.0
                    } else {
                        physicsBody?.velocity.dx = -moveSpeed
                        self.xScale = 1.0
                    }
                }
            }
        }
    
    func jump() {
            isJumping = true
            let jumpForce = CGVector(dx: 0.0, dy: 400.0) // Adjust the jump force as needed
            physicsBody?.applyForce(jumpForce)
            
            // After jumping, set a delay before allowing another jump
            let jumpDelay = SKAction.wait(forDuration: 1.0) // Adjust the delay duration as needed
            run(jumpDelay) { [weak self] in
                self?.isJumping = false
            }
        }
}

extension GameScene: FireBowDelegate {
    
    func fireBow(vector: CGPoint) {
        
        let bullet = SKSpriteNode(imageNamed: "arrow")
        bullet.name = "bullet"
        let xOffset: CGFloat = isCharacterFacingRight ? 20.0 : -20.0
        bullet.position = CGPoint(x: character.position.x + xOffset, y: character.position.y)
        
        let bulletSpeed: CGFloat = 15
        let bulletVelocity = CGVector(dx: bulletSpeed * -vector.x, dy: bulletSpeed * -vector.y)
        
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.enemy
        
//        if bowJoystick.velocity.x > 0 {
//            bullet.xScale = -1.0
//        } else if bowJoystick.velocity.x < 0 {
//            bullet.xScale = 1.0
//        }
        
        addChild(bullet)
        
        bullet.physicsBody?.velocity = bulletVelocity
        
        self.run(SKAction.wait(forDuration: 2)) {
            bullet.removeFromParent()
        }
        for dot in aimLine{
            self.run(SKAction.wait(forDuration: 1)) {
                dot.removeFromParent()
            }
        }
    }
    
    func drawDottedLine(initialVelocityPoint: CGPoint, gravity: CGFloat = 6.8) {
        for dot in aimLine{
            dot.removeFromParent()
        }
        aimLine = []
        
        let xOffset: CGFloat = isCharacterFacingRight ? 20.0 : -20.0
        
        let dotSpacing: CGFloat = 10
        let scene = self
        // Create and add dots along the trajectory
        var currentPosition = CGPoint.zero
        var currentVelocity = CGPoint(x: initialVelocityPoint.x, y: initialVelocityPoint.y)
        
        // Calculate the time it takes to reach the next dot's position
        let totalTime = currentVelocity.y / gravity
        let timeToNextDot = totalTime / dotSpacing
        print(initialVelocityPoint.y)
        //        if initialVelocityPoint.y < 0 {
        //        if initialVelocityPoint.y < 0 {
        while currentPosition.y >= 0 {
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor = SKColor.white
            dot.name = "dot"
            dot.position = CGPoint(x: currentPosition.x + character.position.x + xOffset, y: currentPosition.y + character.position.y)
            scene.addChild(dot)
            aimLine.append(dot)
            
            // Update the position and velocity for the next dot
            currentPosition.x += currentVelocity.x * timeToNextDot
            currentPosition.y += currentVelocity.y * timeToNextDot - 0.5 * gravity * (timeToNextDot * timeToNextDot)
            currentVelocity.y -= gravity * timeToNextDot
            //                scene.run(SKAction.wait(forDuration: 1)) {
            //                    dot.removeFromParent()
            if currentPosition.y == 0{
                break
            }
        }
    }
}


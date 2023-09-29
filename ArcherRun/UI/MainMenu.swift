//
//  MainMenu.swift
//  ArcherRun
//
//  Created by Eduardo Pretto on 28/09/23.
//

import SpriteKit
import GameplayKit

class MainMenu: SKScene {
    
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "Home")
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        background.size = frame.size
        addChild(background)
        
        let startButton = SKSpriteNode(imageNamed: "play")
//        let texture = SKTexture(image: UIImage(named: "play"))
//        startButton.fillTexture = texture
        
        startButton.position = CGPoint(x: size.width/2, y: (size.height / 6) + 10)
        startButton.zPosition = 2
        addChild(startButton)
        
//        startButton.isUserInteractionEnabled
        startButton.name = "startButton"

    }
    
    
    func touchDown(atPoint pos : CGPoint) {

    }
    
    func touchMoved(toPoint pos : CGPoint) {

    }
    
    func touchUp(atPoint pos : CGPoint) {

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let location = t.location(in: self)
            let node = atPoint(location)
            
            if node.name == "startButton"{
//                let gameScene = GameScene(fileNamed: "GameScene")
//                gameScene!.scaleMode = .aspectFill
//
//                // Transition to the game scene
//                let transition = SKTransition.fade(withDuration: 1.0)
//                view?.presentScene(gameScene!, transition: transition)
                
                let newScene = StoryPage(size: frame.size)
                newScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 1.0)
                print(newScene.children)
                self.view?.presentScene(newScene, transition: transition)
            }
        }
    }
    

    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    

}


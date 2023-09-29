//
//  MainMenu.swift
//  ArcherRun
//
//  Created by Eduardo Pretto on 28/09/23.
//

import SpriteKit
import GameplayKit

class StoryPage: SKScene {
    
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "Menu")
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        background.size = frame.size
        addChild(background)
        
        let beginButton = SKSpriteNode(imageNamed: "start")
        
        beginButton.position = CGPoint(x: size.width/2, y: (size.height / 6) + 10)
        beginButton.zPosition = 2
        addChild(beginButton)
        
        let backButton = SKSpriteNode(imageNamed: "back")
        backButton.position = CGPoint(x: 100, y: size.height - 50)
        backButton.zPosition = 2
        addChild(backButton)
        backButton.name = "backButton"
        
//        startButton.isUserInteractionEnabled
        beginButton.name = "beginGame"

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
            
            if node.name == "beginGame"{
                let gameScene = GameScene(fileNamed: "GameScene")
                gameScene!.scaleMode = .aspectFill
                
                // Transition to the game scene
                let transition = SKTransition.fade(withDuration: 1.0)
                view?.presentScene(gameScene!, transition: transition)
            }
            
            if node.name == "backButton"{
                let transitionScene = MainMenu(size: frame.size)
                transitionScene.scaleMode = .aspectFill
                
                // Transition to the game scene
                let transition = SKTransition.fade(withDuration: 1.0)
                view?.presentScene(transitionScene, transition: transition)
            }
        }
    }
    

    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    

}


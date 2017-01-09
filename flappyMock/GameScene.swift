//
//  GameScene.swift
//  flappyMock
//
//  Created by teacher on 9/2/16.
//  Copyright (c) 2016 Mathien. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameState
    {
    case showingLogo, playing, dead
    }

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var plane: SKSpriteNode!
    var scoreLabel: SKLabelNode!

    // holds the logos for the game
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!

    // keeps track of the game state
    var gameState = GameState.showingLogo

    var score = 0
    {
        didSet //called immediately after new value is stored it's a property observer
        {
            scoreLabel.text = "SCORE: \(score)"
        }
    }

    override func didMove(to view: SKView)
    {
        /* Setup your scene here */

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0) //sets gravity
        physicsWorld.contactDelegate = self

        createplane()
        createBackground()
        createMountains()
        createGround()
        createScore()
        createLogos()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {

        switch gameState
        {
        case .showingLogo:

            gameState = .playing

            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run
                { [unowned self] in
            self.plane.physicsBody?.isDynamic = true
            self.rockGenerator()
                }

            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
            logo.run(sequence)


        case .playing:
            plane.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            plane.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
    
        case .dead:
            /// resets the game
            let scene = GameScene(fileNamed: "GameScene")!
            scene.scaleMode = .resizeFill
            let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
            self.view?.presentScene(scene, transition: transition)
        }

}

    override func update(_ currentTime: TimeInterval)
    {
        /* Called before each frame is rendered */
        guard plane != nil else { return }

        // rotates the plane on tap for realistic look to sprite
        let value = plane.physicsBody!.velocity.dy * 0.001
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)

        plane.run(rotate)
    }

// checks for passes adds to score, coin noise and removes rectangle
    func didBegin(_ contact: SKPhysicsContact)
    {
        print("test")
        // determines if you hit a red rectangle could be A or B
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect"
        {
            if contact.bodyA.node == plane
            {
                contact.bodyB.node?.removeFromParent()
            }
            else
            {
                contact.bodyA.node?.removeFromParent()
            }

            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            score += 1
            
            return
        }

        else if contact.bodyA.node == plane || contact.bodyB.node == plane
        {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion")
            {
                explosion.position = plane.position
                addChild(explosion)
            }

            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)
            gameOver.alpha = 1
            gameState = .dead
            plane.removeFromParent()
            speed = 0
        }
    }

    func createScore()
    {
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.fontSize = 24
        scoreLabel.position = CGPoint(x: frame.maxX - 20, y: frame.maxY - 40)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontColor = UIColor.black
        scoreLabel.zPosition = 0

        addChild(scoreLabel)
    }


    func createplane() //function to animate sprite
    {
        let planeTexture = SKTexture(imageNamed: "player-1")
        plane = SKSpriteNode(texture: planeTexture) //sets image to node
        plane.zPosition = 10 //stacking order
        plane.position = CGPoint(x: frame.width / 6, y: frame.height * 0.75) //location on view

        addChild(plane)

        // sets up physics for node
        plane.physicsBody = SKPhysicsBody(texture: planeTexture, size: planeTexture.size())

        // tells us of any collisions
        plane.physicsBody?.contactTestBitMask = (plane.physicsBody?.collisionBitMask)!

        // makes the plane respond to physics
        plane.physicsBody?.isDynamic = false

        // adds the bounce off nothing
        plane.physicsBody?.collisionBitMask = 0

        let frame2 = SKTexture(imageNamed: "player-2")
        let frame3 = SKTexture(imageNamed: "player-3")
        let animation = SKAction.animate(with: [planeTexture, frame2, frame3, frame2], timePerFrame: 0.01)
        let runForever = SKAction.repeatForever(animation)

        plane.run(runForever)
    }

    func createBackground()
    {
        let topBackground = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.14, brightness: 0.97, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.67)) //creates top background
        topBackground.anchorPoint = CGPoint(x: 0.5, y: 1) //sets anchor

        let bottomBackground = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.16, brightness: 0.96, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.33)) //creates bottom back ground
        topBackground.anchorPoint = CGPoint(x: 0.5, y: 1)

        topBackground.position = CGPoint(x: frame.midX, y: frame.height) //location in view
        bottomBackground.position = CGPoint(x: frame.midX, y: bottomBackground.frame.height / 2)

        addChild(topBackground) //adds view
        addChild(bottomBackground)
        
        bottomBackground.zPosition = -40
        topBackground.zPosition = -40
    }

    func createMountains()
    {
        let mountainTexture = SKTexture(imageNamed: "mountains")

        //creates 2 of the same images for seamless transisiton
        for i in 0 ... 1
        {
            let mountainPic = SKSpriteNode(texture: mountainTexture)
            mountainPic.zPosition = -30 // sets in front of blue background
            mountainPic.anchorPoint = CGPoint.zero //bottom left corner
            mountainPic.position = CGPoint(x: (mountainTexture.size().width * CGFloat(i)) - CGFloat(1 * i), y: 100)

            addChild(mountainPic)

            let moveLeft = SKAction.moveBy(x: -mountainTexture.size().width, y: 0, duration: 20)
            let moveReset = SKAction.moveBy(x: mountainTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            mountainPic.run(moveForever)
        }
    }

    func createGround()
    {
        let groundTexture = SKTexture(imageNamed: "ground") //sets image for texture

        for i in 0 ... 1 // loops for infinite look to ground
        {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)

            //adds physics
            ground.physicsBody = SKPhysicsBody(texture: groundTexture, size: groundTexture.size())

            //holds it in place
            ground.physicsBody?.isDynamic = false

            addChild(ground)

            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            ground.run(moveForever)
        }
    }

    func createRocks()
    {
        // creates top and bottom sprites
        let rockTexture = SKTexture(imageNamed: "rock")

        let topRock = SKSpriteNode(texture: rockTexture)

        //sets collision up, but prevents the rocks from falling off screen
        topRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        topRock.physicsBody?.isDynamic = false

        // flips rock
        topRock.zRotation = CGFloat(M_PI)
        topRock.xScale = -1.0 //flips sprite

        let bottomRock = SKSpriteNode(texture: rockTexture)

        //sets collision up, but prevents the rocks from falling off screen
        bottomRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        bottomRock.physicsBody?.isDynamic = false

        bottomRock.zPosition = -20

        topRock.zPosition = -20

        /// creates a collisions sprite after rocks
        let rockCollision = SKSpriteNode(color: UIColor.red, size: CGSize(width: 32, height: frame.height))

        //sets collision up, but prevents the red rectangle from falling off screen
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false

        rockCollision.name = "scoreDetect"

        addChild(topRock)
        addChild(bottomRock)
        addChild(rockCollision)

        /// determines where gap will be randomly
        let xPosition = frame.width + topRock.frame.width

        let max = Int(frame.height / 3)
        let rand = GKRandomDistribution(lowestValue: -100, highestValue: max)
        let yPosition = CGFloat(rand.nextInt())

        let rockDistance : CGFloat = 70 //space between rocks

        //position rocks off right edge and animate them across and remove
        topRock.position = CGPoint(x: xPosition, y: yPosition + topRock.size.height + rockDistance)
        bottomRock.position = CGPoint(x: xPosition, y: yPosition - rockDistance)
        rockCollision.position = CGPoint(x: xPosition + rockCollision.size.width * 2, y: frame.midY)
        rockCollision.zPosition = -50

        let endPosition = frame.width + (topRock.frame.width * 2)

        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        topRock.run(moveSequence)
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
    }

    func rockGenerator()
    {
        // creates a new set of rocks every 3 seconds
        let create = SKAction.run
        {
            self.createRocks()
        }

        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        run(SKAction.repeatForever(sequence))
    }

    func createLogos()
    {
        logo = SKSpriteNode(imageNamed: "logo")

        // places it in the middle
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)

        gameOver = SKSpriteNode(imageNamed: "gameover")

        // places it in the middle
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)

        // set alpha to zero until game over
        gameOver.alpha = 0

        addChild(gameOver)
    }

}

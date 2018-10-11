//
//  ViewController.swift
//  FaceTracking
//
//  Created by Will Saults on 10/8/18.
//  Copyright © 2018 AppVentures. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    enum EnabledFeature {
        case none
        case mesh
        case nose
        case face
    }
    
    var mainNode: SCNNode?
    var mainAnchor: ARFaceAnchor?
    var nose: EmojiNode?
    var leftEye: EmojiNode?
    var rightEye: EmojiNode?
    var mouth: EmojiNode?
    
    let noseOptions = ["👃", "🐽", "💧", " "]
    let eyeOptions = ["👁", "🌕", "🌟", "🔥", "⚽️", "🔎", " "]
    let mouthOptions = ["👄", "👅", "❤️", " "]
    let features = ["nose", "leftEye", "rightEye", "mouth"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        sceneView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        for (feature, indices) in zip(features, featureIndices)  {
            let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
            
            switch feature {
                
            case "leftEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
                
            case "rightEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
                
            case "mouth":
                let jawOpenValue = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.2
                child?.scale = SCNVector3(1.0, 0.8 + jawOpenValue, 1.0)
                
            default:
                break
            }
        }
    }
    
    func removeFeatures(_ node: SCNNode, faceAnchor: ARFaceAnchor) {
        emojiNose().removeFromParentNode()
        emojiLeftEye().removeFromParentNode()
        emojiRightEye().removeFromParentNode()
        emojiMouth().removeFromParentNode()
        updateFeatures(for: node, using: faceAnchor)
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        let results = sceneView.hitTest(location, options: nil)
        if let result = results.first,
            let node = result.node as? EmojiNode {
            node.next()
        }
    }
    
    @IBAction func changeFeature(_ sender: UISegmentedControl) {
        guard let node = mainNode, let faceAnchor = mainAnchor else {
            return
        }
        
        removeFeatures(node, faceAnchor: faceAnchor)
        
        switch sender.selectedSegmentIndex {
        case 1:
            renderMesh(node)
        case 2:
            renderNose(node, faceAnchor: faceAnchor)
            node.geometry?.firstMaterial?.transparency = 0.0
        case 3:
            renderFace(node, faceAnchor: faceAnchor)
            node.geometry?.firstMaterial?.transparency = 0.0
        default:
            renderNone(node)
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let device = sceneView.device else { // this will show an error until you choose a compatible device
            return nil
        }
        let faceGeometry = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceGeometry)
        mainNode = node
        mainAnchor = faceAnchor
        
        renderNone(node)
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
    
        // Added for updating the feature position
        updateFeatures(for: node, using: faceAnchor)
    }
    
    func emojiNose() -> EmojiNode {
        guard let node = nose else {
            let node = EmojiNode(with: noseOptions)
            node.name = "nose"
            nose = node
            return node
        }
        return node
    }
    
    func emojiLeftEye() -> EmojiNode {
        guard let node = leftEye else {
            let node = EmojiNode(with: eyeOptions)
            node.name = "leftEye"
            node.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
            leftEye = node
            return node
        }
        return node
    }
    
    func emojiRightEye() -> EmojiNode {
        guard let node = rightEye else {
            let node = EmojiNode(with: eyeOptions)
            node.name = "rightEye"
            node.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
            rightEye = node
            return node
        }
        return node
    }
    
    func emojiMouth() -> EmojiNode {
        guard let node = mouth else {
            let node = EmojiNode(with: mouthOptions)
            node.name = "mouth"
            mouth = node
            return node
        }
        return node
    }
    
    func renderNone(_ node: SCNNode) {
        node.geometry?.firstMaterial?.transparency = 0.0
    }
    
    func renderMesh(_ node: SCNNode) {
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 1.0
    }
    
    func renderNose(_ node: SCNNode, faceAnchor: ARFaceAnchor) {
        node.addChildNode(emojiNose())
        updateFeatures(for: node, using: faceAnchor)
    }
    
    func renderLeftEye(_ node: SCNNode, faceAnchor: ARFaceAnchor) {
        node.addChildNode(emojiLeftEye())
        updateFeatures(for: node, using: faceAnchor)
    }
    
    func renderRightEye(_ node: SCNNode, faceAnchor: ARFaceAnchor) {
        node.addChildNode(emojiRightEye())
        updateFeatures(for: node, using: faceAnchor)
    }
    
    func renderMouth(_ node: SCNNode, faceAnchor: ARFaceAnchor) {
        node.addChildNode(emojiMouth())
        updateFeatures(for: node, using: faceAnchor)
    }
    
    func renderFace(_ node: SCNNode, faceAnchor: ARFaceAnchor) {
        renderNose(node, faceAnchor: faceAnchor)
        renderMouth(node, faceAnchor: faceAnchor)
        renderLeftEye(node, faceAnchor: faceAnchor)
        renderRightEye(node, faceAnchor: faceAnchor)
    }
}


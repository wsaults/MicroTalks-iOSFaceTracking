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
    
    let noseOptions = ["👃", "🐽", "💧", " "]
    
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
        let child = node.childNode(withName: "nose", recursively: false) as? EmojiNode
        
        let verticies = [anchor.geometry.vertices[9]]
        
        child?.updatePosition(for: verticies)
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
        node.geometry?.firstMaterial?.fillMode = .lines
        
        // Adding the nose
//        node.geometry?.firstMaterial?.transparency = 0.0
//        let noseNode = EmojiNode(with: noseOptions)
//        noseNode.name = "nose"
//        node.addChildNode(noseNode)
//        updateFeatures(for: node, using: faceAnchor)
        return node
    }
    
    // Allowing the mesh to rerender
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let faceAnchor = anchor as? ARFaceAnchor,
//            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
//                return
//        }
//        
//        faceGeometry.update(from: faceAnchor.geometry)
    
    
    // Added for updating the nose position
//    updateFeatures(for: node, using: faceAnchor)
//    }
}


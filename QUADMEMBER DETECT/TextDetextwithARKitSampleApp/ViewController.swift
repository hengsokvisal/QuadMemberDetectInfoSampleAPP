//
//  ViewController.swift
//  TextDetextwithARKitSampleApp
//
//  Created by HengVisal on 6/11/18.
//  Copyright © 2018 HengVisal. All rights reserved.
//

import UIKit
import ARKit
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    let dispatchQueueML = DispatchQueue(label: "visalTest") // A Serial Queue
    var label : String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        sceneView.autoenablesDefaultLighting = true
        captureImage()
    }
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST : REAL WORLD
        // Get Screen Centre
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create 3D Text
            let node : SCNNode = createNewBubbleParentNode(label)
            sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
        }
    }
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        var name: String = ""
        var age: String = ""
        var company : String = ""
        
        if self.label == "Phanith San" {
            name = "Name : Phanith \n"
            age = "Age : 20 \n"
            company = "Company : Quad \n"
        }
        else if self.label == "background"{
            name = "QUAD OFFICE"
            age = ""
            company = ""
        }
        else if self.label == "Sasaki San"
        {
            name = "Name : Sasaki \n"
            age = "Age : 20 \n"
            company = "Company : Quad \n"
        }
        
        let bubbleDepth : Float = 0.01
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        // ===================
        
        // Create CALayer to add to the SCNPlan
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: 400, height: 500)
        layer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        
        // Create CATextlayer to add to the CALayer
        let textLayer = CATextLayer()
        let font = UIFont(name: "Futura", size: 0.15)
        textLayer.font = font
        textLayer.frame = layer.bounds
        textLayer.alignmentMode = .left
        textLayer.string = name+age+company
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.display()
        layer.addSublayer(textLayer)
        
        // Create SCNPlan To Display A FLAT OBJECT
        let display = SCNPlane(width: 1.0, height: 0.75)
        display.firstMaterial?.diffuse.contents = layer
        //=======================

        // DisplayNode NODE
        let (minBound, maxBound) = display.boundingBox
        let displayNode = SCNNode(geometry: display)
        // Centre Node - to Centre-Bottom point
        displayNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        displayNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        
        // BUBBLE PARENT NODE
        let displayNodeParent = SCNNode()
        displayNodeParent.addChildNode(displayNode)
        displayNodeParent.constraints = [billboardConstraint]
        return displayNodeParent
    }
}

extension ViewController{
    func captureImage() -> Void {
        self.dispatchQueueML.async {
            
            self.request()
            self.captureImage()
        }
    }
    
    func request () -> Void {
        guard let Image: CVPixelBuffer = self.sceneView.session.currentFrame?.capturedImage else {return}
        let ciImage = CIImage(cvPixelBuffer: Image)
        
        guard let model = try? VNCoreMLModel(for: quadMLModel().model) else {return}
        let Visionrequest = VNCoreMLRequest(model: model) { (request, err) in
            let response = request.results as? [VNClassificationObservation]
            let result = response?.first
            DispatchQueue.main.async {
                self.label = (result?.identifier)!
            }
            
        }

        // Handler
        let VisionHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        Visionrequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        try? VisionHandler.perform([Visionrequest])
    }
}

extension ViewController {
    override func viewWillAppear(_ animated: Bool) {
        let configure = ARWorldTrackingConfiguration()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints , ARSCNDebugOptions.showWorldOrigin]
        configure.planeDetection = .horizontal
        sceneView.session.run(configure)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }
}
extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}

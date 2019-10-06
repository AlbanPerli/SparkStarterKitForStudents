//
//  ImageRecognition.swift
//  SparkPerso
//
//  Created by AL on 21/01/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit
import Vision
import VideoToolbox

class ImageRecognition {
    static let shared = ImageRecognition()
    
    
    let model = MobileNet()
    
    /*
     This uses the Core ML-generated MobileNet class directly.
     Downside of this method is that we need to convert the UIImage to a
     CVPixelBuffer object ourselves. Core ML does not resize the image for
     you, so it needs to be 224x224 because that's what the model expects.
     */
    func predictUsingCoreML(image: UIImage) -> (UIImage,String)? {
        if let pixelBuffer = image.pixelBuffer(width: 224, height: 224),
            let prediction = try? model.prediction(data: pixelBuffer) {
            let top5 = top(5, prediction.prob)
            var s: [String] = []
            for (i, pred) in top5.enumerated() {
                s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
            }
            
            // This is just to test that the CVPixelBuffer conversion works OK.
            // It should have resized the image to a square 224x224 pixels.
            var imoog: CGImage?
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &imoog)
            return (UIImage(cgImage: imoog!),s.joined())
        }
        return nil
    }
    
    typealias Prediction = (String, Double)
    
    func top(_ k: Int, _ prob: [String: Double]) -> [Prediction] {
        precondition(k <= prob.count)
        
        return Array(prob.map { x in (x.key, x.value) }
            .sorted(by: { a, b -> Bool in a.1 > b.1 })
            .prefix(through: k - 1))
    }
    
}

//
//  ImageResize.swift
//  SparkPerso
//
//  Created by AL on 15/11/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import UIKit

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
}

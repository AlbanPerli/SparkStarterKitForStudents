//
//  Color+Utils.swift
//  SupportingContent
//
//  Created by Jeff Payan on 2018-08-08.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation
import UIKit

struct RGBValues {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
}

extension UIColor {
    func rgbValues() -> RGBValues {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        
        getRed(&r, green: &g, blue: &b, alpha: nil)

        return RGBValues(r: r, g: g, b: b)
    }
}

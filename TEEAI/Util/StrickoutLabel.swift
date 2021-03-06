//
//  StrickoutLabel.swift
//  sst-ios
//
//  Created by 天星 on 2018/1/22.
//  Copyright © 2018年 ios. All rights reserved.
//

import UIKit

class StrickoutLabel: UILabel {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
      
        let context = UIGraphicsGetCurrentContext()!
        self.textColor.setStroke()
        let y : CGFloat = self.frame.height/2
        context.move(to: CGPoint.init(x: 0, y: y))
        let size = (self.text! as NSString).size(withAttributes: [NSAttributedString.Key.font:self.font])
        context.addLine(to: CGPoint.init(x: size.width, y: y))
        context.strokePath()
        
    }
}

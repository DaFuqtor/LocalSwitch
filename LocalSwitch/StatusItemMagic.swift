//
//  StatusItemMagic.swift
//  LocalSwitch
//
//  Created by Arthur Ginzburg on 08/09/2019.
//  Copyright © 2019 DaFuqtor. All rights reserved.
//

import Cocoa

public extension NSImage {
  func rotated(_ angle: CGFloat) -> NSImage {
    let img = NSImage(size: self.size, flipped: false, drawingHandler: { rect -> Bool in
      let (width, height) = (rect.size.width, rect.size.height)
      let transform = NSAffineTransform()
      transform.translateX(by: width / 2, yBy: height / 2)
      transform.rotate(byDegrees: angle)
      transform.translateX(by: -width / 2, yBy: -height / 2)
      transform.concat()
      self.draw(in: rect)
      return true
    })
    img.isTemplate = self.isTemplate // preserve the underlying image's template setting
    return img
  }
}

var iconDegrees = 0

extension NSStatusBarButton {
  func spin(from: Int = 0, to: Int = -940) {
    if iconDegrees <= to {
      iconDegrees = from
      
      self.image = NSImage(named: "statusIcon")!.rotated(CGFloat(iconDegrees))
    } else {
      
      if iconDegrees > from {
        iconDegrees -= 1
      } else if iconDegrees < from - 10 && iconDegrees > from - 30 {
        iconDegrees -= 2
      } else if iconDegrees < from - 30 && iconDegrees > from - 60 {
        iconDegrees -= 3
      } else if iconDegrees < from - 60 && iconDegrees > from - 100 {
        iconDegrees -= 4
      } else if iconDegrees < from - 100 && iconDegrees > from - 150 {
        iconDegrees -= 5
      } else if iconDegrees < from - 150 && iconDegrees > from - 220 {
        iconDegrees -= 6
      } else if iconDegrees < from - 220 && iconDegrees > from - 300 {
        iconDegrees -= 7
      } else if iconDegrees < from - 300 && iconDegrees > from - 390 {
        iconDegrees -= 8
      } else if iconDegrees < from - 390 && iconDegrees > to + 450 {
        iconDegrees -= 9
      } else if iconDegrees < to + 450 && iconDegrees > to + 360 {
        iconDegrees -= 8
      } else if iconDegrees < to + 360 && iconDegrees > to + 280 {
        iconDegrees -= 7
      } else if iconDegrees < to + 280 && iconDegrees > to + 210 {
        iconDegrees -= 6
      } else if iconDegrees < to + 210 && iconDegrees > to + 150 {
        iconDegrees -= 5
      } else if iconDegrees < to + 150 && iconDegrees > to + 100 {
        iconDegrees -= 4
      } else if iconDegrees < to + 100 && iconDegrees > to + 60 {
        iconDegrees -= 3
      } else if iconDegrees < to + 60 && iconDegrees > to + 30 {
        iconDegrees -= 3
      } else if iconDegrees < to + 30 && iconDegrees > to + 10 {
        iconDegrees -= 2
      } else if iconDegrees < to + 10 && iconDegrees > to {
        iconDegrees -= 1
      }
      else {
        iconDegrees -= 1
      }
      
      self.image = NSImage(named: "statusIcon")!.rotated(CGFloat(iconDegrees))
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.0000001) {
        self.spin()
      }
    }
  }
  
  func fadeOut(_ step: CGFloat = 0.01) {
    if !self.appearsDisabled {
      self.alphaValue -= step
      
      if self.alphaValue > 0.3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
          self.fadeOut()
        }
      } else {
        self.appearsDisabled = true
        self.alphaValue = 1
      }
    }
  }
  
  func fadeIn(_ step: CGFloat = 0.02) {
      if self.alphaValue == 1 {
        self.appearsDisabled = false
        self.alphaValue = 0.3
      }
      
      self.alphaValue += step
      
      if self.alphaValue < 1 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
          self.fadeIn()
        }
      } else {
        self.appearsDisabled = false
        self.alphaValue = 1
      }
  }
}

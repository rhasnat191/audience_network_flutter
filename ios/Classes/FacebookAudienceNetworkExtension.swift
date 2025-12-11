// import Foundation
// /**
//  * convert (hexString <-> UIColor)
//  */

// extension UIColor {
//     convenience init(hexString:String) {
//         let hexString:NSString = hexString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) as NSString
//         let scanner            = Scanner(string: hexString as String)
        
//         if (hexString.hasPrefix("#")) {
//             scanner.scanLocation = 1
//         }
        
//         var color:UInt32 = 0
//         scanner.scanHexInt32(&color)
        
//         let mask = 0x000000FF
//         let r = Int(color >> 16) & mask
//         let g = Int(color >> 8) & mask
//         let b = Int(color) & mask
        
//         let red   = CGFloat(r) / 255.0
//         let green = CGFloat(g) / 255.0
//         let blue  = CGFloat(b) / 255.0
        
//         self.init(red:red, green:green, blue:blue, alpha:1)
//     }
    
//     func toHexString() -> String {
//         var r:CGFloat = 0
//         var g:CGFloat = 0
//         var b:CGFloat = 0
//         var a:CGFloat = 0
        
//         getRed(&r, green: &g, blue: &b, alpha: &a)
        
//         let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
//         return NSString(format:"#%06x", rgb) as String
//     }
// }

import UIKit
import Foundation

extension UIColor {
    
    /// Initialize UIColor from hex string.
    /// Supports:
    /// - "#RRGGBB"
    /// - "RRGGBB"
    /// - "#RGB"
    /// - "RGB"
    /// - "#RRGGBBAA" (Alpha)
    convenience init(hexString: String) {
        let cleaned = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()

        var hexValue: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&hexValue)

        let r, g, b, a: CGFloat

        switch cleaned.count {
        case 3: // RGB (12-bit)
            r = CGFloat((hexValue >> 8) & 0xF) / 15
            g = CGFloat((hexValue >> 4) & 0xF) / 15
            b = CGFloat(hexValue & 0xF) / 15
            a = 1.0

        case 6: // RRGGBB (24-bit)
            r = CGFloat((hexValue >> 16) & 0xFF) / 255
            g = CGFloat((hexValue >> 8) & 0xFF) / 255
            b = CGFloat(hexValue & 0xFF) / 255
            a = 1.0

        case 8: // RRGGBBAA (32-bit)
            r = CGFloat((hexValue >> 24) & 0xFF) / 255
            g = CGFloat((hexValue >> 16) & 0xFF) / 255
            b = CGFloat((hexValue >> 8) & 0xFF) / 255
            a = CGFloat(hexValue & 0xFF) / 255

        default:
            // Invalid hex format; fallback to white.
            r = 1
            g = 1
            b = 1
            a = 1
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    
    /// Convert UIColor to hex string "#RRGGBB"
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb = (Int(r * 255) << 16)
                | (Int(g * 255) << 8)
                | (Int(b * 255) << 0)

        return String(format: "#%06X", rgb)
    }
}
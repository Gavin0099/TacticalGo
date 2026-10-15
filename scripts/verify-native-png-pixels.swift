import Foundation
import ImageIO
import CoreGraphics
import CryptoKit

// Xcode converts standalone PNGs to CgBI. Compare decoded visible pixels,
// retaining original and compiled file hashes separately; do not rewrite art.
func pixels(_ path: String) throws -> [String:Any] {
    let url = URL(fileURLWithPath:path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL,nil),
          let image = CGImageSourceCreateImageAtIndex(source,0,nil),
          let space = CGColorSpace(name:CGColorSpace.sRGB),
          let context = CGContext(data:nil,width:image.width,height:image.height,bitsPerComponent:8,
                                  bytesPerRow:image.width*4,space:space,
                                  bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
          let bytes = context.data else { throw NSError(domain:"NativePNG",code:1) }
    context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))
    let digest = SHA256.hash(data:Data(bytes:bytes,count:image.width*image.height*4)).map { String(format:"%02x",$0) }.joined()
    return ["width":image.width,"height":image.height,"visiblePremultipliedSRGB_SHA256":digest]
}
let one = try pixels(CommandLine.arguments[1]),two = try pixels(CommandLine.arguments[2])
let equal = one["width"] as? Int == two["width"] as? Int && one["height"] as? Int == two["height"] as? Int && one["visiblePremultipliedSRGB_SHA256"] as? String == two["visiblePremultipliedSRGB_SHA256"] as? String
print(String(data:try JSONSerialization.data(withJSONObject:["source":one,"compiled":two,"equal":equal],options:.sortedKeys),encoding:.utf8)!)
exit(equal ? 0:1)

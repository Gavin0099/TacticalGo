import Foundation
import Vision
import ImageIO
let folder=URL(fileURLWithPath:CommandLine.arguments[1])
let paths=try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil).filter {$0.pathExtension=="png"}.sorted {$0.lastPathComponent<$1.lastPathComponent}
func textAt(_ i:Int)throws->String {
    guard let s=CGImageSourceCreateWithURL(paths[i] as CFURL,nil),let image=CGImageSourceCreateImageAtIndex(s,0,nil) else {return ""}
    let r=VNRecognizeTextRequest();r.recognitionLevel = .accurate;r.recognitionLanguages=["en-US","zh-Hant"];r.usesLanguageCorrection=false
    try VNImageRequestHandler(cgImage:image).perform([r])
    return (r.results ?? []).compactMap {$0.topCandidates(1).first?.string}.joined(separator:" ").replacingOccurrences(of:" ",with:"")
}
var prepared:Int?=nil
for i in stride(from:0,to:paths.count,by:6) {
    let t=try textAt(i)
    if t.contains("1AP") {prepared=i}
    if let p=prepared,t.contains("0AP") {
        for j in max(p,i-6)...i {
            let exact=try textAt(j)
            if exact.contains("0AP") {
                let v:[String:Any] = ["native_visual_onset":Double(j)/60,"frame":j,"fps":60,"prepared_frame":p,"observable":"prepared1AP then confirmed0AP (computer commander capture); coarse search refined every 60fps frame","confirmed_text":exact]
                print(String(data:try JSONSerialization.data(withJSONObject:v,options:.sortedKeys),encoding:.utf8)!);exit(0)
            }
        }
    }
}
fputs("Missing prepared-to-confirmed native label transition\n",stderr);exit(1)

import Foundation
import Vision
import ImageIO
let folder = URL(fileURLWithPath:CommandLine.arguments[1]),mana = CommandLine.arguments[2]
let paths = try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil).filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
func textAt(_ i: Int) throws -> String {
    guard let source = CGImageSourceCreateWithURL(paths[i] as CFURL,nil),let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { return "" }
    let request = VNRecognizeTextRequest();request.recognitionLevel = .accurate;request.recognitionLanguages = ["zh-Hant"];request.usesLanguageCorrection = true;request.automaticallyDetectsLanguage = true
    try VNImageRequestHandler(cgImage:image).perform([request])
    return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator:"").replacingOccurrences(of:" ",with:"")
}
var prepared: Int?
for i in stride(from:0,to:paths.count,by:6) {
    let text = try textAt(i)
    if text.contains("2AP") && text.contains("6能量") { prepared = i }
    if let p = prepared,text.contains("1AP"),text.contains(mana+"能量") {
        for j in max(p,i-6)...i {
            let exact = try textAt(j)
            if exact.contains("1AP") && exact.contains(mana+"能量") {
                let result: [String:Any] = ["native_visual_onset":Double(j)/60,"frame":j,"fps":60,"prepared_frame":p,"observable":"actual HUD resources 2 AP/6 energy to 1 AP/"+mana+" energy; frame search at60fps","confirmed_text":exact]
                print(String(data:try JSONSerialization.data(withJSONObject:result,options:.sortedKeys),encoding:.utf8)!);exit(0)
            }
        }
    }
}
fputs("No prepared-to-confirmed resource transition found\n",stderr);exit(1)

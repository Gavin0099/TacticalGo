import Foundation
import Vision
import ImageIO

// Independent observable receipt indicator: 2 AP/4 Mana becomes1 AP/2 Mana.
// Native video PTS and recorder wall time differ; do not align sound by wall guess.
let folder=URL(fileURLWithPath:CommandLine.arguments[1])
let paths=try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil).filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
var prepared=false
for (index,path) in paths.enumerated() {
    guard let source=CGImageSourceCreateWithURL(path as CFURL,nil),let image=CGImageSourceCreateImageAtIndex(source,0,nil) else { continue }
    let request=VNRecognizeTextRequest();request.recognitionLevel = .accurate
    request.recognitionLanguages=["en-US","zh-Hant"];request.usesLanguageCorrection=false
    try VNImageRequestHandler(cgImage:image).perform([request])
    let text=(request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator:" ").replacingOccurrences(of:" ",with:"")
    if text.contains("2AP") && text.contains("4Mana") { prepared=true }
    if prepared && text.contains("1AP") && text.contains("2Mana") {
        print("{\"native_visual_onset\":\(Double(index)/60),\"frame\":\(index),\"fps\":60,\"observable\":\"2 AP/4 Mana to1 AP/2 Mana after new scene\"}")
        exit(0)
    }
}
throw NSError(domain:"Missing prepared-to-confirmed transition",code:1)

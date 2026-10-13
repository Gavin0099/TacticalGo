import XCTest
@testable import TacticalGoVisuals

final class PhoneBoardGeometryTests: XCTestCase {
    func testFixedSlotsReserveExactly332PointsAndDependOnlyOnViewport() {
        for (w,h) in [(375.0,613.0),(390,759),(402,778),(414,812)] {
            let layout = PhoneMatchLayout(width:w,height:h)
            XCTAssertEqual(layout.width,w-12)
            XCTAssertEqual(layout.boardHeight,min((w-12)*1.04,h-332),accuracy:0.0001)
            XCTAssertLessThanOrEqual(layout.boardHeight+332,h)
            for _ in 0..<20 { XCTAssertEqual(layout,PhoneMatchLayout(width:w,height:h)) }
        }
        XCTAssertEqual(PhoneMatchLayout(width:.nan,height:.infinity).boardHeight,0)
        XCTAssertEqual(PhoneMatchLayout(width:5,height:200).width,0)
    }
    func testPhoneSevenAndNineAllCellHitAndUprightFigureExtentsInsideFixedViewport() {
        for (w,h) in [(375.0,613.0),(390,759),(402,778),(414,812)] { for n in [7,9] {
            let layout = PhoneMatchLayout(width:w,height:h)
            let f = Anim01Geometry(width:layout.width,height:layout.boardHeight,boardSize:n,focusedPhone:true)
            for y in 0..<n { for x in 0..<n {
                let row = Double(y)/Double(n-1),span = 0.74+0.12*row
                let cx = f.x + (0.5 + (Double(x)/Double(n-1)-0.5)*span)*f.width
                let cy = f.y + (0.18+0.65*row)*f.height
                XCTAssertGreaterThanOrEqual(cx-f.pitch*0.5,-0.001)
                XCTAssertLessThanOrEqual(cx+f.pitch*0.5,layout.width+0.001)
                XCTAssertGreaterThanOrEqual(cy-f.pitch*0.98,-0.001)
                XCTAssertLessThanOrEqual(cy+f.pitch*0.5,layout.boardHeight+0.001)
            } }
        } }
    }
    func testFocusedNineEnlargesGridAndKeepsEdgeFiguresAndHitCellsVisible() {
        for (w,h) in [(363.0,288.0),(390.0,375.0),(414.0,395.0)] {
            let old = Anim01Geometry(width:w,height:h,boardSize:9)
            let focused = Anim01Geometry(width:w,height:h,boardSize:9,focusedNine:true)
            XCTAssertGreaterThan(focused.pitch,old.pitch*1.19)
            XCTAssertEqual(focused.height/focused.width,1.125,accuracy:0.00001)
            // Published projection and maximum upright token half-width, independent of production centre code.
            for y in 0..<9 { for x in 0..<9 {
                let row = Double(y)/8, span = 0.74+0.12*row
                let cx = focused.x + (0.5 + (Double(x)/8-0.5)*span)*focused.width
                let cy = focused.y + (0.18+0.65*row)*focused.height
                XCTAssertGreaterThanOrEqual(cx-focused.pitch*0.5,0)
                XCTAssertLessThanOrEqual(cx+focused.pitch*0.5,w)
                XCTAssertGreaterThanOrEqual(cy-focused.pitch*0.90,0)
                XCTAssertLessThanOrEqual(cy+focused.pitch*0.5,h)
            } }
        }
    }
    func testSevenAndOriginalFramingRemainUnchanged() {
        let seven = Anim01Geometry(width:390,height:345,boardSize:7)
        XCTAssertEqual(seven,Anim01Geometry(width:390,height:345,boardSize:7,focusedNine:true))
        XCTAssertEqual(seven.width,345/1.125,accuracy:0.00001)
        XCTAssertEqual(seven.height,345,accuracy:0.00001)
        XCTAssertEqual(seven.x,(390-seven.width)/2,accuracy:0.00001)
        XCTAssertEqual(seven.y,0,accuracy:0.00001)
    }
}

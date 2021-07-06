import XCTest
import Sundials


final class VectorTests: XCTestCase {
    static var allTests = [
        ("testValueSemantics", testValueSemantics),
        ("testAlgebraicOperations", testAlgebraicOperations)
    ]

    func testValueSemantics() {
        var x = Vector(size: 3)
        x[0] = 0
        x[1] = 1
        x[2] = 2

        var y = x
        var z = y
        
        y[0] = 100
        y[1] = 101
        y[2] = 102
        
        z[0] += 1000
        z[1] += 1000
        z[2] += 1000
        
        XCTAssertNotEqual(x, y)
        XCTAssertNotEqual(x, z)
        XCTAssertEqual(y, [100, 101, 102])
        XCTAssertEqual(z, [1000, 1001, 1002])
    }
    
    func testAlgebraicOperations() {
        var x: Vector = [1, 2, 3]
        var y: Vector = [10, 20, 30]

        // Addition and subtraction
        XCTAssertEqual(x + .zero, x)
        XCTAssertEqual(.zero + x, +x)
        XCTAssertEqual(y - .zero, y)
        XCTAssertEqual(.zero - y, -y)

        let sum = x + y
        XCTAssertEqual(sum, [11, 22, 33])

        let difference = x - y
        XCTAssertEqual(difference, [-9, -18, -27])

        // In-place addition and subtraction
        x += .zero
        XCTAssertEqual(x, [1, 2, 3])
        y -= .zero
        XCTAssertEqual(y, [10, 20, 30])

        var x0 = Vector.zero
        x0 += x
        XCTAssertEqual(x0, +x)
        var y0 = Vector.zero
        y0 -= y
        XCTAssertEqual(y0, -y)

        var inPlaceSum: Vector = [100, 200, 300]
        inPlaceSum += x
        XCTAssertEqual(inPlaceSum, [101, 202, 303])

        var inPlaceDifference: Vector = [1000, 2000, 3000]
        inPlaceDifference -= y
        XCTAssertEqual(inPlaceDifference, [990, 1980, 2970])

        // Multiplication by a scalar
        XCTAssertEqual(Vector.zero * 1.234, .zero)
        XCTAssertEqual(1.234 * Vector.zero, .zero)
        XCTAssertEqual(3 * x, [3, 6, 9])
        XCTAssertEqual(y * 5, [50, 100, 150])
    }
}

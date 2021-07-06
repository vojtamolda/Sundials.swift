import XCTest
import Sundials


final class MatrixTests: XCTestCase {
    static var allTests = [
        ("testValueSemantics", testValueSemantics),
        ("testAlgebraicOperations", testAlgebraicOperations),
    ]

    func testValueSemantics() {
        var X = Matrix(rows: 2, columns: 2)
        X[0, 0] = 0; X[0, 1] = 1
        X[1, 0] = 2; X[1, 1] = 3

        var Y = X
        var Z = Y

        Y[0, 0] = 100; Y[0, 1] = 101
        Y[1, 0] = 102; Y[1, 1] = 103
        
        Z[0, 0] += 1000; Z[0, 1] += 1000
        Z[1, 0] += 1000; Z[1, 1] += 1000
        
        XCTAssertNotEqual(X, Y)
        XCTAssertNotEqual(X, Z)
    }
    
    func testAlgebraicOperations() {
        var X: Matrix = [[1, 2], [3, 4]]
        var Y: Matrix = [[10, 20], [30, 40]]
        
        XCTAssertEqual(-X, [[-1, -2], [-3, -4]])
        XCTAssertEqual(+X, [[+1, +2], [+3, +4]])

        // Addition and subtraction
        XCTAssertEqual(X + .zero, X)
        XCTAssertEqual(.zero + X, +X)
        XCTAssertEqual(Y - .zero, Y)
        XCTAssertEqual(.zero - Y, -Y)
        
        let S = X + Y
        XCTAssertEqual(S, [[11, 22], [33, 44]])
        
        let D = X - Y
        XCTAssertEqual(D, [[-9, -18], [-27, -36]])

        // In-place addition and subtraction
        X += .zero
        XCTAssertEqual(X, [[1, 2], [3, 4]])
        Y -= .zero
        XCTAssertEqual(Y, [[10, 20], [30, 40]])
        
        var X0 = Matrix.zero
        X0 += X
        XCTAssertEqual(X0, +X)
        var Y0 = Matrix.zero
        Y0 -= Y
        XCTAssertEqual(Y0, -Y)

        var inPlaceS: Matrix = [[100, 200], [300, 400]]
        inPlaceS += X
        XCTAssertEqual(inPlaceS, [[101, 202], [303, 404]])

        var inPlaceD: Matrix = [[1000, 2000], [3000, 4000]]
        inPlaceD -= Y
        XCTAssertEqual(inPlaceD, [[990, 1980], [2970, 3960]])
    }
}

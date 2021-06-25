import XCTest
import CSundials


final class SUNLinSolTests: XCTestCase {
    static var allTests = [
        ("test_dense", test_dense),
    ]
    
    let N: sunindextype = 3
    
    func test_dense() {
        let A = SUNDenseMatrix(N, N)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }
        let ACols = SUNDenseMatrix_Cols(A)!
        ACols[0]![0] = 1; ACols[1]![0] = 0; ACols[2]![0] = 0
        ACols[0]![1] = 0; ACols[1]![1] = 1; ACols[2]![1] = 0
        ACols[0]![2] = 0; ACols[1]![2] = 0; ACols[2]![2] = 1
        
        let b = N_VNew_Serial(N)
        XCTAssertNotNil(b)
        defer { N_VDestroy(b) }
        let bData = N_VGetArrayPointer(b)!
        bData[0] = 1
        bData[1] = 1
        bData[2] = 1
        
        let LS = SUNLinSol_Dense(b, A)
        XCTAssertNotNil(LS)
        defer { SUNLinSolFree(LS) }
        
        let x = N_VNew_Serial(N)
        XCTAssertNotNil(x)
        defer { N_VDestroy(x) }
        
        var flag = SUNLinSolSetup(LS, A)
        XCTAssertEqual(flag, SUNLS_SUCCESS)
        
        flag = SUNLinSolSolve(LS, A, x, b, .ulpOfOne)
        XCTAssertEqual(flag, SUNLS_SUCCESS)

        let xRef = N_VNew_Serial(N)
        XCTAssertNotNil(xRef)
        defer { N_VDestroy(xRef) }
        let xRefData = N_VGetArrayPointer(xRef)!
        xRefData[0] = 1
        xRefData[1] = 1
        xRefData[2] = 1
        XCTAssertAlmostEqual(x, xRef, .ulpOfOne, .ulpOfOne)
    }
}

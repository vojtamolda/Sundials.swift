import XCTest
import CSundials


final class SUNMatrixTests: XCTestCase {
    static var allTests = [
        ("test_todo", test_dense),
        ("test_multiply", test_multiply),
    ]
    
    let M: sunindextype = 3
    let N: sunindextype = 2

    func test_dense() {
        let A = SUNDenseMatrix(M, N)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }
        
        XCTAssertEqual(SUNMatGetID(A), SUNMATRIX_DENSE)
    }

    func test_multiply() {
        let A = SUNDenseMatrix(M, N)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }

        let x = N_VNew_Serial(M)
        XCTAssertNotNil(x)
        defer { N_VDestroy(x) }
        N_VConst(1, x)
        
        let y = N_VNew_Serial(M)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
                
        var flag = SUNMatMatvecSetup(A)
        XCTAssertEqual(flag, SUNMAT_SUCCESS)
        
        flag = SUNMatMatvec(A, x, y)
        XCTAssertEqual(flag, SUNMAT_SUCCESS)        
    }
}

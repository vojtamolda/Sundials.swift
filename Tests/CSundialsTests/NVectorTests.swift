import XCTest
import COpenMPI
import CSundials


final class NVectorTests: XCTestCase {
    static var allTests = [
        ("test_serial", test_serial),
        ("test_parallel", test_parallel),
    ]
    
    let N: sunindextype = 3
    
    func test_serial() {
        let one = N_VNew_Serial(N)
        XCTAssertNotNil(one)
        defer { N_VDestroy(one) }
        N_VConst(-1, one)
        
        let two = N_VNew_Serial(N)
        XCTAssertNotNil(two)
        defer { N_VDestroy(two) }
        N_VConst(-2, two)

        XCTAssertEqual(absDotProduct(one, two), realtype(2 * N))
    }
    
    func test_parallel() {
        MPI_Init(nil, nil)
        var size: Int32 = 0
        MPI_Comm_size(MPI_COMM_WORLD, &size)

        let one = N_VNew_Parallel(MPI_COMM_WORLD, N, N)
        XCTAssertNotNil(one)
        defer { N_VDestroy(one) }
        N_VConst(-1, one)

        let two = N_VNew_Parallel(MPI_COMM_WORLD, N, N)
        XCTAssertNotNil(two)
        defer { N_VDestroy(two) }
        N_VConst(-2, two)
        
        XCTAssertEqual(absDotProduct(one, two), realtype(2 * N))
    }
    
    func absDotProduct(_ x: N_Vector?, _ y: N_Vector?) -> realtype {
        XCTAssertNotNil(x)
        XCTAssertNotNil(y)

        N_VAbs(x, x)
        N_VAbs(y, y)
        return N_VDotProd(x, y)
    }
}

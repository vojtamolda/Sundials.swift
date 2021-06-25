import XCTest
import CSundials


final class IDATests: XCTestCase {
    static var allTests = [
        ("test_idaRoberts_dns", test_idaRoberts_dns)
    ]

    /// Solves simple mixed, non-linear DAE system.
    ///
    /// This simple example DAE problem, due to Robertson, is from chemical kinetics, and consists
    /// of the following three equations:
    ///
    /// ```
    /// dy1/dt = -0.04*y1 + 1.e4*y2*y3
    /// dy2/dt = +0.04*y1 - 1.e4*y2*y3 - 3.e7*y2**2
    ///      1 = y1 + y2 + y3
    /// ```
    ///
    /// The problem is solved on the interval from `t = 0` to `t = 4e10`, with initial conditions
    /// `y1 = 1`, `y2 = y3 = 0`.
    ///
    /// While integrating the system, we also use the root-finding feature to find the points at which
    /// `y1 = 1e-4` or at which `y3 = 0.01`.
    ///
    /// The problem is solved with IDA using the dense linear solver, with a user-supplied Jacobian.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/ida/serial/idaRoberts_dns.c
    ///
    func test_idaRoberts_dns() {
        let NEQ: sunindextype = 3
        let NOUT = 12

        // MARK: Setup

        let yy = N_VNew_Serial(NEQ)
        XCTAssertNotNil(yy)
        defer { N_VDestroy(yy) }
        let yArray = N_VGetArrayPointer(yy)!
        yArray[0] = 1
        yArray[1] = 0
        yArray[2] = 0
        
        let yp = N_VNew_Serial(NEQ)
        XCTAssertNotNil(yp)
        defer { N_VDestroy(yp) }
        let ypArray = N_VGetArrayPointer(yp)!
        ypArray[0] = -0.04
        ypArray[1] = +0.04
        ypArray[2] = 0

        let avtol = N_VNew_Serial(NEQ)
        XCTAssertNotNil(avtol)
        defer { N_VDestroy(avtol) }
        let avtolArray = N_VGetArrayPointer(avtol)!
        avtolArray[0] = 1e-8
        avtolArray[1] = 1e-6
        avtolArray[2] = 1e-6
        
        let rtol = 1e-4
        let t0 = 0.0
        
        var idaMem = IDACreate()
        XCTAssertNotNil(idaMem)
        defer { IDAFree(&idaMem) }

        var flag = IDAInit(idaMem, resrob, t0, yy, yp)
        XCTAssertEqual(flag, IDA_SUCCESS)

        flag = IDASVtolerances(idaMem, rtol, avtol)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        flag = IDARootInit(idaMem, 2, grob)
        XCTAssertEqual(flag, IDA_SUCCESS)

        let A = SUNDenseMatrix(NEQ, NEQ)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }

        let LS = SUNLinSol_Dense(yy, A)
        XCTAssertNotNil(LS)
        defer { SUNLinSolFree(LS) }

        flag = IDASetLinearSolver(idaMem, LS, A)
        XCTAssertEqual(flag, IDA_SUCCESS)

        flag = IDASetJacFn(idaMem, jacrob)
        XCTAssertEqual(flag, IDA_SUCCESS)

        // MARK: Timestepping
        
        var iout = 1
        var tout = 0.4
        var t = t0
        
        while iout <= NOUT {
            switch IDASolve(idaMem, tout, &t, yy, yp, IDA_NORMAL) {
            case IDA_SUCCESS:
                iout += 1
                tout *= 10.0

            case IDA_ROOT_RETURN:
                var roots: (CInt, CInt) = (0, 0)
                flag = IDAGetRootInfo(idaMem, &roots.0)
                XCTAssertEqual(flag, IDA_SUCCESS)

            default:
                XCTFail()
            }
        }

        // MARK: Verification

        let ref = N_VClone(yy)
        defer { N_VDestroy(ref) }
        let refArray = N_VGetArrayPointer(ref)!
        refArray[0] = 5.2083474251394888e-08
        refArray[1] = 2.0833390772616859e-13
        refArray[2] = 9.9999994791631752e-01
        
        N_VScale(10, avtol, avtol)
        XCTAssertAlmostEqual(yy, ref, rtol, avtol)
        
        // MARK: Problem

        func resrob(tres: realtype, yy: N_Vector!, yp: N_Vector!,
                    rr: N_Vector!, userData: UnsafeMutableRawPointer?) -> CInt {
            let yyVal = N_VGetArrayPointer(yy)!
            let ypVal = N_VGetArrayPointer(yp)!
            let rVal = N_VGetArrayPointer(rr)!

            rVal[0] = -0.04 * yyVal[0] + 1.0e4 * yyVal[1] * yyVal[2]
            rVal[1] = -rVal[0] - 3.0e7 * yyVal[1] * yyVal[1] - ypVal[1]
            rVal[0] -= ypVal[0]
            rVal[2] = yyVal[0] + yyVal[1] + yyVal[2] - 1.0
            
            return IDA_SUCCESS
        }

        func grob(t: realtype, yy: N_Vector!, yp: N_Vector!,
                  gout: UnsafeMutablePointer<realtype>!,
                  userData: UnsafeMutableRawPointer?) -> CInt {
            let yyVal = N_VGetArrayPointer(yy)!

            gout[0] = yyVal[0] - 0.0001
            gout[1] = yyVal[2] - 0.01

            return IDA_SUCCESS
        }
        
        func jacrob(t: realtype, cj: realtype, yy: N_Vector!, yp: N_Vector!,
                 resvec: N_Vector!, J: SUNMatrix!,
                 userData: UnsafeMutableRawPointer?,
                 tmp1: N_Vector!, tmp2: N_Vector!, tmp3: N_Vector!) -> CInt {

            let yyVal = N_VGetArrayPointer(yy)!

            let JCols = SUNDenseMatrix_Cols(J)!
            JCols[0]![0] = -0.04 - cj
            JCols[1]![0] = 1.0e4 * yyVal[2]
            JCols[2]![0] = 1.0e4 * yyVal[1]
            
            JCols[0]![1] = 0.04
            JCols[1]![1] = -1.0e4 * yyVal[2] - 6.0e7 * yyVal[1] - cj
            JCols[2]![1] = -1.0e4 * yyVal[1]
            
            JCols[0]![2] = 1.0
            JCols[1]![2] = 1.0
            JCols[2]![2] = 1.0
            
            return IDA_SUCCESS
        }
    }
}

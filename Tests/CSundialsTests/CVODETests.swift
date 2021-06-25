import XCTest
import CSundials


final class CVODETests: XCTestCase {
    static var allTests = [
        ("test_cvRoberts_dns", test_cvRoberts_dns)
    ]

    /// Solves simple non-linear system of ODEs.
    ///
    /// This simple example ODE problem, due to Robertson, is from chemical kinetics, and consists
    /// of the following three equations:
    ///
    /// ```
    /// dy1/dt = -0.04*y1 + 1e4*y2*y3
    /// dy2/dt = +0.04*y1 - 1e4*y2*y3 - 3e7*y2**2
    /// dy3/dt = - dy2/dt - dy3/dt
    /// ```
    /// 
    /// The problem is solved on the interval from `t = 0` to `t = 4e10`, with initial conditions
    /// `y1 = 1, y2 = y3 = 0`.
    ///
    /// While integrating the system, the example also use the root-finding feature to find the points at which
    /// `y1 = 1e-4` or at which `y3 = 0.01`.
    ///
    /// The problem is solved with CVODE integrator using the dense linear solver, with a user-supplied
    /// Jacobian.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/cvode/serial/cvRoberts_dns.c
    ///
    func test_cvRoberts_dns() {
        let NEQ: sunindextype = 3
        let Y1 = 1.0
        let Y2 = 0.0
        let Y3 = 0.0
        let RTOL = 1.0e-4
        let ATOL1 = 1.0e-8
        let ATOL2 = 1.0e-14
        let ATOL3 = 1.0e-6
        let T0 = 0.0
        let T1 = 0.4
        let TMULT = 10.0
        let NOUT = 12

        // MARK: Setup

        let y = N_VNew_Serial(NEQ)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
        let yArray = N_VGetArrayPointer(y)!
        yArray[0] = Y1
        yArray[1] = Y2
        yArray[2] = Y3

        let abstol = N_VNew_Serial(NEQ)
        XCTAssertNotNil(abstol)
        defer { N_VDestroy(abstol) }
        let abstolArray = N_VGetArrayPointer(abstol)!
        abstolArray[0] = ATOL1
        abstolArray[1] = ATOL2
        abstolArray[2] = ATOL3
        
        var cvodeMem = CVodeCreate(CV_BDF)
        XCTAssertNotNil(cvodeMem)
        defer { CVodeFree(&cvodeMem) }

        var flag = CVodeInit(cvodeMem, f, T0, y)
        XCTAssertEqual(flag, CV_SUCCESS)

        flag = CVodeSVtolerances(cvodeMem, RTOL, abstol)
        XCTAssertEqual(flag, CV_SUCCESS)
        
        flag = CVodeRootInit(cvodeMem, 2, g)
        XCTAssertEqual(flag, CV_SUCCESS)

        let A = SUNDenseMatrix(NEQ, NEQ)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }

        let LS = SUNLinSol_Dense(y, A)
        XCTAssertNotNil(LS)
        defer { SUNLinSolFree(LS) }

        flag = CVodeSetLinearSolver(cvodeMem, LS, A)
        XCTAssertEqual(flag, CV_SUCCESS)

        flag = CVodeSetJacFn(cvodeMem, Jac)
        XCTAssertEqual(flag, CV_SUCCESS)

        // MARK: Timestepping
        
        var iout = 1
        var tout = T1
        var t: realtype = 0.0
        
        while iout <= NOUT {
            switch CVode(cvodeMem, tout, y, &t, CV_NORMAL) {
            case CV_SUCCESS:
                iout += 1
                tout *= TMULT

            case CV_ROOT_RETURN:
                var roots: (CInt, CInt) = (0, 0)
                flag = CVodeGetRootInfo(cvodeMem, &roots.0)
                XCTAssertEqual(flag, CV_SUCCESS)

            default:
                XCTFail()
            }
        }

        // MARK: Verification

        let ref = N_VClone(y)
        defer { N_VDestroy(ref) }
        let refArray = N_VGetArrayPointer(ref)!
        refArray[0] = 5.2083495894337328e-08
        refArray[1] = 2.0833399429795671e-13
        refArray[2] = 9.9999994791629776e-01
        
        N_VScale(10, abstol, abstol)
        XCTAssertAlmostEqual(y, ref, RTOL, abstol)
        
        // MARK: Problem

        func f(t: realtype, y: N_Vector!, ydot: N_Vector!,
               userData: UnsafeMutableRawPointer?) -> CInt {
            let yArray = N_VGetArrayPointer(y)!
            let (y1, y2, y3) = (yArray[0], yArray[1], yArray[2])
            
            let yd1 = -0.04 * y1 + 1.0e4 * y2 * y3
            let yd3 = 3.0e7 * y2 * y2
            let yd2 = -yd1 - yd3
            
            let ydArray = N_VGetArrayPointer(ydot)!
            (ydArray[0], ydArray[1], ydArray[2]) = (yd1, yd2, yd3)
            
            return CV_SUCCESS
        }

        func g(t: realtype, y: N_Vector!, gout: UnsafeMutablePointer<realtype>!,
               userData: UnsafeMutableRawPointer?) -> CInt {
            let yArray = N_VGetArrayPointer(y)!
            let (y1, y3) = (yArray[0], yArray[2])
            
            gout[0] = y1 - 0.0001
            gout[1] = y3 - 0.01

            return CV_SUCCESS
        }
        
        func Jac(t: realtype, y: N_Vector!, fy: N_Vector!, J: SUNMatrix!,
                 userData: UnsafeMutableRawPointer?,
                 tmp1: N_Vector!, tmp2: N_Vector!, tmp3: N_Vector!) -> CInt {
            
            let yArray = N_VGetArrayPointer(y)!
            let (y2, y3) = (yArray[1], yArray[2])

            let JCols = SUNDenseMatrix_Cols(J)!
            JCols[0]![0] = -0.04
            JCols[1]![0] = 1.0e4 * y3
            JCols[2]![0] = 1.0e4 * y2
            
            JCols[0]![1] = 0.04
            JCols[1]![1] = -1.0e4 * y3 - 6.0e7 * y2
            JCols[2]![1] = -1.0e4 * y2
            
            JCols[0]![2] = 0.0
            JCols[1]![2] = 6.0e7 * y2
            JCols[2]![2] = 0.0

            return CV_SUCCESS
        }
    }
}

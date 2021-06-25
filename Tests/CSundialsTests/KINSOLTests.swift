import XCTest
import CSundials


final class KINSOLTests: XCTestCase {
    static var allTests = [
        ("test_kinRoberts_fp", test_kinRoberts_fp),
        ("test_kinFerTron_dns", test_kinFerTron_dns)

    ]

    /// Solves a simple non-linear system of algebraic equations.
    ///
    /// The problem is from chemical kinetics, and consists of solving the first time step in a backward Euler
    /// time-stepping scheme for the following three rate equations:
    ///
    /// ```
    /// dy1/dt = -0.04*y1 + 1e4*y2*y3
    /// dy2/dt = +0.04*y1 - 1e4*y2*y3 - 3e2*(y2)^2
    /// dy3/dt = 3e2*(y2)^2
    /// ```
    ///
    /// on the interval from `t = 0.0` to `t = 0.1`, with initial conditions: `y1 = 1.0`,
    /// `y2 = y3 = 0`. The problem is stiff.
    ///
    /// The problem is solved with KINSOL non-linear solver using the fixed point strategy.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/kinsol/serial/kinRoberts_fp.c
    ///
    func test_kinRoberts_fp() {
        let NEQ: sunindextype = 3
        let TOL = 1e-10
        let PRIORS = 2

        // MARK: Setup

        let y = N_VNew_Serial(NEQ)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
        let yArray = N_VGetArrayPointer(y)!
        yArray[0] = 1
        yArray[1] = 0
        yArray[2] = 0

        let scale = N_VNew_Serial(NEQ)
        XCTAssertNotNil(scale)
        defer { N_VDestroy(scale) }
        N_VConst(1, scale)
        
        var kMem = KINCreate()
        XCTAssertNotNil(kMem)
        defer { KINFree(&kMem) }
        
        var flag = KINSetMAA(kMem, PRIORS)
        XCTAssertEqual(flag, KIN_SUCCESS)
        
        flag = KINInit(kMem, funcRoberts, y)
        XCTAssertEqual(flag, KIN_SUCCESS)

        flag = KINSetFuncNormTol(kMem, TOL)
        XCTAssertEqual(flag, KIN_SUCCESS)

        // MARK: Solution

        flag = KINSol(kMem, y, KIN_FP, scale, scale)
        XCTAssertEqual(flag, KIN_SUCCESS)

        var fnorm = Double.nan
        flag = KINGetFuncNorm(kMem, &fnorm)
        XCTAssertEqual(flag, KIN_SUCCESS)

        // MARK: Verification

        let ref = N_VClone(y)
        XCTAssertNotNil(ref)
        defer { N_VDestroy(ref) }
        let refArray = N_VGetArrayPointer(ref)!
        refArray[0] = 9.9678538655358029e-01
        refArray[1] = 2.9530060962800345e-03
        refArray[2] = 2.6160735013975683e-04

        XCTAssertAlmostEqual(y, ref, 1e-4, 1e-6)
        
        // MARK: Problem

        func funcRoberts(y: N_Vector!, g: N_Vector!,
                         userData: UnsafeMutableRawPointer?) -> CInt {
            let (Y00, Y10, Y20) = (1.0, 0.0, 0.0)
            let DSTEP = 0.1

            let yArray = N_VGetArrayPointer(y)!
            let (y0, y1, y2) = (yArray[0], yArray[1], yArray[2])
            
            let yd0 = (-0.04 * y0 + 1e4 * y1 * y2) * DSTEP
            let yd2 = (3e2 * y1 * y1) * DSTEP

            let gArray = N_VGetArrayPointer(g)!
            gArray[0] = Y00 + yd0
            gArray[1] = Y10 - yd0 - yd2
            gArray[2] = Y20 + yd2

            return KIN_SUCCESS
        }
    }
    
    /// Solves a nonlinear system with analytical solution due to Ferraris and Tronconi.
    ///
    /// The problem involves a blend of trigonometric and exponential terms
    /// ```
    /// 0.5*sin(x1*x2) - 0.25*x2/pi - 0.5*x1 = 0
    /// (1 - 0.25/pi)*(exp(2*x1) - e) + e*x2/pi - 2*e*x1 = 0
    /// ```
    /// such that
    /// ```
    /// 0.25 <= x1 <= 1
    /// 1.5  <= x2 <= 2*pi
    /// ```
    /// Constraints are imposed to make all components of the solution positive.
    ///
    /// The treatment of the bound constraints on `x1` and `x2` is done using
    /// the additional variables
    /// ```
    /// l1 = x1 - x1_min >= 0
    /// L1 = x1 - x1_max <= 0
    /// l2 = x2 - x2_min >= 0
    /// L2 = x2 - x2_max >= 0
    /// ```
    /// And then using the constraint feature in KINSOL to impose
    /// ```
    /// l1 >= 0    l2 >= 0
    /// L1 <= 0    L2 <= 0
    /// ```
    ///
    /// The Ferraris-Tronconi test problem has two known solutions. The nonlinear system is solved by
    /// KINSOL with non-linear solver using the fixed point strategy. Different combinations of
    /// globalization and Jacobian update strategies are exercised. Different initial guesses lead to one
    /// or the other of the known solutions.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/kinsol/serial/test_kinFerTron_dns.c
    ///
    func test_kinFerTron_dns() {
        let NVAR: sunindextype = 2
        let NEQ: sunindextype = 3 * NVAR
        let FTOL = 1e-5
        let STOL = 1e-5
        
        struct UserData {
            let lowerBound: [Double]
            let upperBound: [Double]
        }
        var userData = UserData(
            lowerBound: [0.25, 1.5],
            upperBound: [1, 2 * .pi]
        )
        
        // MARK: Setup

        let u1 = N_VNew_Serial(NEQ) // Guess close to [0.29945, 2.83693]
        XCTAssertNotNil(u1)
        defer { N_VDestroy(u1) }
        let u1Array = N_VGetArrayPointer(u1)!
        u1Array[0] = userData.lowerBound[0] // x1
        u1Array[1] = userData.lowerBound[1] // x2
        u1Array[2] = u1Array[0] - userData.lowerBound[0] // l1
        u1Array[3] = u1Array[0] - userData.upperBound[0] // L1
        u1Array[4] = u1Array[1] - userData.lowerBound[1] // l2
        u1Array[5] = u1Array[1] - userData.upperBound[1] // L2

        let u2 = N_VNew_Serial(NEQ) // Guess close to [0.5, pi]
        XCTAssertNotNil(u2)
        defer { N_VDestroy(u2) }
        let u2Array = N_VGetArrayPointer(u2)!
        u2Array[0] = (userData.lowerBound[0] + userData.upperBound[0]) / 2 // x1
        u2Array[1] = (userData.lowerBound[1] + userData.upperBound[1]) / 2 // x2
        u2Array[2] = u2Array[0] - userData.lowerBound[0] // l1
        u2Array[3] = u2Array[0] - userData.upperBound[0] // L1
        u2Array[4] = u2Array[1] - userData.lowerBound[1] // l2
        u2Array[5] = u2Array[1] - userData.upperBound[1] // L2
        
        let c = N_VNew_Serial(NEQ)
        XCTAssertNotNil(c)
        defer { N_VDestroy(c) }
        let cPointer = N_VGetArrayPointer(c)!
        cPointer[0] = 0  // No constraint on x1
        cPointer[1] = 0  // No constraint on x2
        cPointer[2] = +1 // l1 = x1 - x1_min >= 0
        cPointer[3] = -1 // L1 = x1 - x1_max <= 0
        cPointer[4] = +1 // l2 = x2 - x2_min >= 0
        cPointer[5] = -1 // L1 = x2 - x2_max <= 0
        
        let u = N_VNew_Serial(NEQ)
        XCTAssertNotNil(u)
        defer { N_VDestroy(u) }
        
        let s = N_VNew_Serial(NEQ)
        XCTAssertNotNil(s)
        defer { N_VDestroy(s) }
        N_VConst(1, s)

        var kMem = KINCreate()
        XCTAssertNotNil(kMem)
        defer { KINFree(&kMem) }

        var flag = KINSetUserData(kMem, &userData)
        XCTAssertEqual(flag, KIN_SUCCESS)

        flag = KINSetConstraints(kMem, c)
        XCTAssertEqual(flag, KIN_SUCCESS)

        flag = KINSetFuncNormTol(kMem, FTOL)
        XCTAssertEqual(flag, KIN_SUCCESS)
        
        flag = KINSetScaledStepTol(kMem, STOL)
        XCTAssertEqual(flag, KIN_SUCCESS)

        flag = KINInit(kMem, `func`, u)
        XCTAssertEqual(flag, KIN_SUCCESS)

        let J = SUNDenseMatrix(NEQ, NEQ)
        XCTAssertNotNil(J)
        defer { SUNMatDestroy(J)}
        
        let LS = SUNLinSol_Dense(u, J)
        XCTAssertNotNil(LS)
        defer { SUNLinSolFree(LS) }

        flag = KINSetLinearSolver(kMem, LS, J)
        XCTAssertEqual(flag, KIN_SUCCESS)
        
        // MARK: Solution
        
        func solve(_ u0: N_Vector!, _ glstr: Int32, _ mset: Int) {
            flag = KINSetMaxSetupCalls(kMem, mset)
            XCTAssertEqual(flag, KIN_SUCCESS)
            
            N_VScale(1, u0, u)

            flag = KINSol(kMem, u, glstr, s, s)
            XCTAssertEqual(flag, KIN_SUCCESS)
            
            let uArray = N_VGetArrayPointer(u)!
            uArray[2] = 0; uArray[3] = 0
            uArray[4] = 0; uArray[5] = 0
        }
        
        // MARK: Verification

        let uRef1 = N_VClone(u)
        XCTAssertNotNil(uRef1)
        defer { N_VDestroy(uRef1) }
        let uRef1Array = N_VGetArrayPointer(uRef1)!
        uRef1Array[0] = 0.29945
        uRef1Array[1] = 2.83693
        uRef1Array[2] = 0
        uRef1Array[3] = 0
        uRef1Array[4] = 0
        uRef1Array[5] = 0

        solve(u1, KIN_NONE, 1)
        XCTAssertAlmostEqual(u, uRef1, 1e-5, 1e-5)
        solve(u1, KIN_LINESEARCH, 1)
        XCTAssertAlmostEqual(u, uRef1, 1e-5, 1e-5)
        solve(u1, KIN_NONE, 0)
        XCTAssertAlmostEqual(u, uRef1, 1e-5, 1e-5)
        solve(u1, KIN_LINESEARCH, 0)
        XCTAssertAlmostEqual(u, uRef1, 1e-5, 1e-5)

        let uRef2 = N_VClone(u)
        XCTAssertNotNil(uRef2)
        defer { N_VDestroy(uRef2) }
        let uRef2Array = N_VGetArrayPointer(uRef2)!
        uRef2Array[0] = 0.5
        uRef2Array[1] = .pi
        uRef2Array[2] = 0
        uRef2Array[3] = 0
        uRef2Array[4] = 0
        uRef2Array[5] = 0

        solve(u2, KIN_NONE, 1)
        XCTAssertAlmostEqual(u, uRef2, 1e-5, 1e-5)
        solve(u2, KIN_LINESEARCH, 1)
        XCTAssertAlmostEqual(u, uRef2, 1e-5, 1e-5)
        solve(u2, KIN_NONE, 0)
        XCTAssertAlmostEqual(u, uRef2, 1e-5, 1e-5)
        solve(u2, KIN_LINESEARCH, 0)
        XCTAssertAlmostEqual(u, uRef2, 1e-5, 1e-5)

        // MARK: Problem

        func `func`(u: N_Vector!, f: N_Vector!,
                    userData: UnsafeMutableRawPointer!) -> CInt {
            let data = userData.assumingMemoryBound(to: UserData.self).pointee

            let uArray = N_VGetArrayPointer(u)!
            let (x1, x2) = (uArray[0], uArray[1])
            let (l1, L1) = (uArray[2], uArray[3])
            let (l2, L2) = (uArray[4], uArray[5])
            let e = exp(1.0)
            let pi = Double.pi

            let fArray = N_VGetArrayPointer(f)!
            fArray[0] = 0.5 * sin(x1*x2) - 0.25*x2/pi - 0.5*x1
            fArray[1] = (1 - 0.25/pi) * (exp(2*x1) - e) + e*x2/pi - 2*e*x1
            fArray[2] = l1 - x1 + data.lowerBound[0]
            fArray[3] = L1 - x1 + data.upperBound[0]
            fArray[4] = l2 - x2 + data.lowerBound[1]
            fArray[5] = L2 - x2 + data.upperBound[1]

            return KIN_SUCCESS
        }
    }
}

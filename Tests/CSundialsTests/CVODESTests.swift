import XCTest
import CSundials


final class CVODESTests: XCTestCase {
    static var allTests = [
        ("test_cvsRoberts_FSA_dns", test_cvsRoberts_FSA_dns)
    ]

    /// Solves simple non-linear system of ODEs with forward sensitivity analysis.
    ///
    /// This simple example ODE problem, due to Robertson, is from chemical kinetics, and consists
    /// of the following three equations:
    ///
    /// ```
    /// dy1/dt = -p1*y1 + p2*y2*y3
    /// dy2/dt = +p1*y1 - p2*y2*y3 - p3*y2**2
    /// dy3/dt = p3*y2*y2
    /// ```
    ///
    /// The problem is solved on the interval from `t = 0` to `t = 4e10`, with initial conditions
    /// `y1 = 1, y2 = y3 = 0`. The reaction rates are `p1 = 0.04`, `p2 = 1e4`
    /// and `p3 = 3e7`. The problem is stiff.
    ///
    /// The problem is solved with CVODES integrator using the dense linear solver, with a user-supplied
    /// Jacobian. CVODES solver can compute sensitivities with respect to the problem parameters `p1`,
    /// `p2`, and `p3`. The sensitivity right hand side is given analytically through the user routine `fS`
    /// (of type `SensRhs1Fn`). Any of three sensitivity methods (_SIMULTANEOUS_, _STAGGERED_,
    /// and _STAGGERED1_) can be used. Sensitivities may be included in the error test or not be setting
    /// the `errCon` variable.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/cvodes/serial/cvsRoberts_FSA_dns.c
    ///
    func test_cvsRoberts_FSA_dns() {
        let NEQ: sunindextype = 3
        let Y1 = 1.0
        let Y2 = 0.0
        let Y3 = 0.0
        let T0 = 0.0
        let T1 = 0.4
        let TMULT = 10.0
        let NOUT = 12
        let NS: Int32 = 3
        
        struct UserData {
            var p: [Double]
        }

        // MARK: Setup

        let y = N_VNew_Serial(NEQ)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
        let yArray = N_VGetArrayPointer(y)!
        yArray[0] = Y1
        yArray[1] = Y2
        yArray[2] = Y3
        
        var cvodeMem = CVodeCreate(CV_BDF)
        XCTAssertNotNil(cvodeMem)
        defer { CVodeFree(&cvodeMem) }

        var flag = CVodeInit(cvodeMem, f, T0, y)
        XCTAssertEqual(flag, CV_SUCCESS)
        
        flag = CVodeWFtolerances(cvodeMem, ewt)
        XCTAssertEqual(flag, CV_SUCCESS)
        
        var data = UserData(p: [0.04, 1e4, 3e7])
        flag = CVodeSetUserData(cvodeMem, &data)
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

        // MARK: Sensitivity

        let yS = N_VCloneVectorArray(NS, y)
        XCTAssertNotNil(yS)
        defer { N_VDestroyVectorArray(yS, NS) }
        for i in 0 ..< Int(NS) {
            N_VConst(0, yS![i])
        }
        
        let sensitivityMethod = CV_SIMULTANEOUS // Or CV_STAGGERED, CV_STAGGERED1
        flag = CVodeSensInit1(cvodeMem, NS, sensitivityMethod, fS, yS)
        XCTAssertEqual(flag, CV_SUCCESS)
        
        flag = CVodeSensEEtolerances(cvodeMem)
        XCTAssertEqual(flag, CV_SUCCESS)
        
        let errCon = SUNTRUE // Or SUNFALSE
        flag = CVodeSetSensErrCon(cvodeMem, errCon)
        XCTAssertEqual(flag, CV_SUCCESS)
        
        flag = CVodeSetSensParams(cvodeMem, nil, &data.p, nil)
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
                
                flag = CVodeGetSens(cvodeMem, &t, yS)
                XCTAssertEqual(flag, CV_SUCCESS)

            default:
                XCTFail()
            }
        }

        // MARK: Verification

        let RTOL = 1e-4
        let atol = N_VClone(y)
        defer { N_VDestroy(atol) }
        let atolArray = N_VGetArrayPointer(atol)!
        atolArray[0] = 1e-8
        atolArray[1] = 1e-14
        atolArray[2] = 1e-6
        N_VScale(10, atol, atol)
        
        let ref = N_VClone(y)
        defer { N_VDestroy(ref) }
        let refArray = N_VGetArrayPointer(ref)!
        refArray[0] = 5.2083495894337328e-08
        refArray[1] = 2.0833399429795671e-13
        refArray[2] = 9.9999994791629776e-01
        XCTAssertAlmostEqual(y, ref, RTOL, atol)
        
        flag = CVodeGetSens(cvodeMem, &t, yS)
        XCTAssertEqual(flag, CV_SUCCESS)
        let ySref = N_VCloneVectorArray(NS, yS![0])
        XCTAssertNotNil(ySref)
        defer { N_VDestroyVectorArray(ySref, NS) }
        
        let ySref0Array = N_VGetArrayPointer(ySref![0])!
        ySref0Array[0] = -2.6618e-06
        ySref0Array[1] = -5.4901e-12
        ySref0Array[2] = 2.6619e-06
        XCTAssertAlmostEqual(yS![0], ySref![0], 1e-4, 1e-6)

        let ySref1Array = N_VGetArrayPointer(ySref![1])!
        ySref1Array[0] = 1.0763e-11
        ySref1Array[1] = 2.2422e-17
        ySref1Array[2] = -1.0763e-11
        XCTAssertAlmostEqual(yS![1], ySref![1], 1e-4, 1e-6)

        let ySref2Array = N_VGetArrayPointer(ySref![2])!
        ySref2Array[0] = -1.7339e-15
        ySref2Array[1] = -6.9355e-21
        ySref2Array[2] = 1.7339e-15
        XCTAssertAlmostEqual(yS![2], ySref![2], 1e-4, 1e-6)
        
        // MARK: Problem

        func f(t: realtype, y: N_Vector!, ydot: N_Vector!,
               userData: UnsafeMutableRawPointer!) -> CInt {
            let data = userData.assumingMemoryBound(to: UserData.self).pointee
            let (p1, p2, p3) = (data.p[0], data.p[1], data.p[2])

            let yArray = N_VGetArrayPointer(y)!
            let (y1, y2, y3) = (yArray[0], yArray[1], yArray[2])
            
            let yd1 = -p1*y1 + p2*y2*y3
            let yd3 = p3*y2*y2
            let yd2 = -yd1 - yd3
            
            let ydArray = N_VGetArrayPointer(ydot)!
            (ydArray[0], ydArray[1], ydArray[2]) = (yd1, yd2, yd3)

            return CV_SUCCESS
        }
        
        func fS(Ns: CInt, t: realtype, y: N_Vector!, ydot: N_Vector!,
                iS: CInt, yS: N_Vector!, ySdot: N_Vector!,
                userData: UnsafeMutableRawPointer!,
                tmp1: N_Vector!, tmp2: N_Vector!) -> CInt {
            let data = userData.assumingMemoryBound(to: UserData.self).pointee
            let (p1, p2, p3) = (data.p[0], data.p[1], data.p[2])
    
            let yArray = N_VGetArrayPointer(y)!
            let (y1, y2, y3) = (yArray[0], yArray[1], yArray[2])
    
            let ySArray = N_VGetArrayPointer(yS)!
            let (s1, s2, s3) = (ySArray[0], ySArray[1], ySArray[2])
            
            var sd1 = -p1*s1 + p2*y3*s2 + p2*y2*s3
            var sd3 = 2*p3*y2*s2
            var sd2 = -sd1 - sd3
            
            switch (iS) {
            case 0:
              sd1 -= y1
              sd2 += y1
            case 1:
              sd1 += y2*y3
              sd2 -= y2*y3
            case 2:
              sd2 -= y2*y2
              sd3 += y2*y2
            default:
              break
            }
            
            let ySdotArray = N_VGetArrayPointer(ySdot)!
            ySdotArray[0] = sd1
            ySdotArray[1] = sd2
            ySdotArray[2] = sd3

            return CV_SUCCESS
        }
        
        func Jac(t: realtype, y: N_Vector!, fy: N_Vector!, J: SUNMatrix!,
                 userData: UnsafeMutableRawPointer!,
                 tmp1: N_Vector!, tmp2: N_Vector!, tmp3: N_Vector!) -> CInt {
            let data = userData.assumingMemoryBound(to: UserData.self).pointee
            let (p1, p2, p3) = (data.p[0], data.p[1], data.p[2])
            
            let yArray = N_VGetArrayPointer(y)!
            let (y2, y3) = (yArray[1], yArray[2])

            let JCols = SUNDenseMatrix_Cols(J)!
            JCols[0]![0] = -p1
            JCols[1]![0] = p2 * y3
            JCols[2]![0] = p2 * y2
            
            JCols[0]![1] = p1
            JCols[1]![1] = -p2 * y3 - 2 * p3 * y2
            JCols[2]![1] = -p2 * y2
            
            JCols[0]![2] = 0.0
            JCols[1]![2] = 2 * p3 * y2
            JCols[2]![2] = 0.0

            return CV_SUCCESS
        }
        
        func ewt(y: N_Vector!, w: N_Vector!,
                 userData: UnsafeMutableRawPointer!) -> CInt {
            let RTOL = 1e-4
            let ATOL1 = 1e-8
            let ATOL2 = 1e-14
            let ATOL3 = 1e-6

            let yArray = N_VGetArrayPointer(y)!
            let wArray = N_VGetArrayPointer(w)!

            let rtol = RTOL
            let atol = [ATOL1, ATOL2, ATOL3]

            for i in 0 ..< Int(N_VGetLength(y)) {
                let yy = yArray[i]
                let ww = rtol * abs(yy) + atol[i]
                if ww <= 0 { return CV_ILL_INPUT }
                wArray[i] = 1 / ww
            }
    
            return CV_SUCCESS
        }
    }
}

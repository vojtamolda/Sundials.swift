import XCTest
import CSundials


final class IDASTests: XCTestCase {
    static var allTests = [
        ("test_idasRoberts_FSA_dns", test_idasRoberts_FSA_dns)
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
    /// The problem is solved with IDAS using the dense linear solver, with a user-supplied Jacobian. IDAS
    /// solver can compute sensitivities with respect to the problem parameters `p1`, `p2`, and `p3`.
    /// The sensitivity right hand side is given analytically through the user routine `fS` (of type
    /// `SensRhs1Fn`). Any of two sensitivity methods (_SIMULTANEOUS_ and _STAGGERED_) can
    /// be used. Sensitivities may be included in the error test or not be setting the `errCon` variable.
    ///
    /// While integrating the system, we also use the quadrature feature to find an integral of solution in
    /// time. Parameter of these integrals with respect to the problem parameters is also checked.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/ida/serial/idaRoberts_dns.c
    ///
    func test_idasRoberts_FSA_dns() {
        let NEQ: sunindextype = 3
        let NQA: sunindextype = 2
        let NOUT = 12
        let T0 = 0.0
        let T1 = 0.4
        let NS: Int32 = 3
        
        var cvodeMem = CVodeCreate(CV_BDF)
        
        struct UserData {
            var p: [Double]
            var coef: Double
        }

        // MARK: Setup

        let y = N_VNew_Serial(NEQ)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
        let yArray = N_VGetArrayPointer(y)!
        yArray[0] = 1
        yArray[1] = 0
        yArray[2] = 0
        
        let yp = N_VNew_Serial(NEQ)
        XCTAssertNotNil(yp)
        defer { N_VDestroy(yp) }
        let ypArray = N_VGetArrayPointer(yp)!
        ypArray[0] = 0.1
        ypArray[1] = 0
        ypArray[2] = 0
        
        var idaMem = IDACreate()
        XCTAssertNotNil(idaMem)
        defer { IDAFree(&idaMem) }

        var flag = IDAInit(idaMem, res, T0, y, yp)
        XCTAssertEqual(flag, IDA_SUCCESS)

        let rtol = 1e-4
        let abstol = N_VNew_Serial(NEQ)
        XCTAssertNotNil(abstol)
        defer { N_VDestroy(abstol) }
        let abstolArray = N_VGetArrayPointer(abstol)!
        abstolArray[0] = 1e-8
        abstolArray[1] = 1e-14
        abstolArray[2] = 1e-6
        flag = IDASVtolerances(idaMem, rtol, abstol)
        XCTAssertEqual(flag, IDA_SUCCESS)

        let id = N_VNew_Serial(NEQ)
        XCTAssertNotNil(id)
        defer { N_VDestroy(id) }
        let idArray = N_VGetArrayPointer(id)!
        idArray[0] = 1.0
        idArray[1] = 1.0
        idArray[2] = 0.0
        flag = IDASetId(idaMem, id)
        XCTAssertEqual(flag, IDA_SUCCESS)

        var data = UserData(p: [0.04, 1e4, 3e7], coef: 0.5)
        flag = IDASetUserData(idaMem, &data)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        let A = SUNDenseMatrix(NEQ, NEQ)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }

        let LS = SUNLinSol_Dense(y, A)
        XCTAssertNotNil(LS)
        defer { SUNLinSolFree(LS) }

        flag = IDASetLinearSolver(idaMem, LS, A)
        XCTAssertEqual(flag, IDA_SUCCESS)

        // MARK: Sensitivity

        let yS = N_VCloneVectorArray(NS, y)
        XCTAssertNotNil(yS)
        defer { N_VDestroyVectorArray(yS, NS) }
        for i in 0 ..< Int(NS) {
            N_VConst(0, yS![i])
        }
        
        let ypS = N_VCloneVectorArray(NS, yp)
        XCTAssertNotNil(ypS)
        defer { N_VDestroyVectorArray(ypS, NS) }
        for i in 0 ..< Int(NS) {
            N_VConst(0, ypS![i])
        }
        
        let sensitivityMethod = IDA_SIMULTANEOUS // Or IDA_STAGGERED
        flag = IDASensInit(idaMem, NS, sensitivityMethod, resS, yS, ypS)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        flag = IDASensEEtolerances(idaMem)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        let errCon = SUNTRUE // Or SUNFALSE
        flag = IDASetSensErrCon(idaMem, errCon)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        var pbar = data.p
        flag = IDASetSensParams(idaMem, &data.p, &pbar, nil)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        // MARK: Quadratures

        let yQ = N_VNew_Serial(NQA)
        XCTAssertNotNil(yQ)
        defer { N_VDestroy(yQ) }
        N_VConst(0, yQ)
        flag = IDAQuadInit(idaMem, rhsQ, yQ)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        let yQS = N_VCloneVectorArray(NS, yQ)
        defer { N_VDestroyVectorArray(yQS, NS) }
        XCTAssertNotNil(yQS)
        for i in 1 ..< Int(NS) {
            N_VConst(0, yQS![i])
        }

        flag = IDAQuadSensInit(idaMem, nil, yQS)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        // MARK: Initial Condition
        
        flag = IDACalcIC(idaMem, IDA_YA_YDP_INIT, T1)
        XCTAssertEqual(flag, IDA_SUCCESS)

        flag = IDAGetConsistentIC(idaMem, y, yp)
        XCTAssertEqual(flag, IDA_SUCCESS)
        
        flag = IDAGetSensConsistentIC(idaMem, yS, ypS)
        XCTAssertEqual(flag, IDA_SUCCESS)

        // MARK: Timestepping
        
        var iout = 1
        var tout = T1
        var t = T0
        
        while iout <= NOUT {
            switch IDASolve(idaMem, tout, &t, y, yp, IDA_NORMAL) {
            case IDA_SUCCESS:
                iout += 1
                tout *= 10.0

            default:
                XCTFail()
            }
        }

        // MARK: Verification

        let ref = N_VClone(y)
        defer { N_VDestroy(ref) }
        let refArray = N_VGetArrayPointer(ref)!
        refArray[0] = 5.2083474251394888e-08
        refArray[1] = 2.0833390772616859e-13
        refArray[2] = 9.9999994791631752e-01
        N_VScale(10, abstol, abstol)
        XCTAssertAlmostEqual(y, ref, rtol, abstol)
        
        flag = IDAGetSens(idaMem, &t, yS)
        XCTAssertEqual(flag, IDA_SUCCESS)
        let ySref = N_VCloneVectorArray(NS, yS![0])
        XCTAssertNotNil(ySref)
        defer { N_VDestroyVectorArray(ySref, NS) }
        
        let ySref0Array = N_VGetArrayPointer(ySref![0])!
        ySref0Array[0] = -2.6329e-06
        ySref0Array[1] = -5.2729e-12
        ySref0Array[2] = 2.6329e-06
        XCTAssertAlmostEqual(yS![0], ySref![0], 1e-4, 1e-6)

        let ySref1Array = N_VGetArrayPointer(ySref![1])!
        ySref1Array[0] = 1.0532e-11
        ySref1Array[1] = 2.1092e-17
        ySref1Array[2] = -1.0532e-11
        XCTAssertAlmostEqual(yS![1], ySref![1], 1e-4, 1e-6)

        let ySref2Array = N_VGetArrayPointer(ySref![2])!
        ySref2Array[0] = -1.7530e-15
        ySref2Array[1] = -7.0120e-21
        ySref2Array[2] = 1.7530e-15
        XCTAssertAlmostEqual(yS![2], ySref![2], 1e-4, 1e-6)

        flag = IDAGetQuad(idaMem, &t, yQ)
        XCTAssertEqual(flag, IDA_SUCCESS)
        let yQref = N_VClone(yQ)
        XCTAssertNotNil(yQref)
        defer { N_VDestroy(yQref) }
        let yQrefArray = N_VGetArrayPointer(yQref)!
        yQrefArray[0] = 4.0000e+10 // Q1
        yQrefArray[1] = 2.0000e+10 // Q2
        XCTAssertAlmostEqual(yQ, yQref, 1e-4, 1e-6)

        flag = IDAGetQuadSens(idaMem, &t, yQS)
        XCTAssertEqual(flag, IDA_SUCCESS)
        let yQSref = N_VCloneVectorArray(NS, yQS![0])
        defer { N_VDestroyVectorArray(yQSref, NS) }

        let yQSref0Array = N_VGetArrayPointer(yQSref![0])!
        yQSref0Array[0] = 1.4878e+06 // dQ1/dp1
        yQSref0Array[1] = 1.4508e+06 // dQ2/dp2
        XCTAssertAlmostEqual(yQS![0], yQSref![0], 1e-3, 1e-4)
        
        let yQSref1Array = N_VGetArrayPointer(yQSref![1])!
        yQSref1Array[0] = -5.9466e+00 // dQ1/dp2
        yQSref1Array[1] = -5.8009e+00 // dQ2/dp2
        XCTAssertAlmostEqual(yQS![1], yQSref![1], 1e-3, 1e-4)
        
        let yQSref2Array = N_VGetArrayPointer(yQSref![2])!
        yQSref2Array[0] = 9.9111e-04  // dQ1/dp3
        yQSref2Array[1] = 9.6733e-04  // dQ2/dp3
        XCTAssertAlmostEqual(yQS![2], yQSref![2], 1e-3, 1e-4)

        // MARK: Problem

        func res(tres: realtype, yy: N_Vector!, yp: N_Vector!,
                 resval: N_Vector!, userData: UnsafeMutableRawPointer!
        ) -> CInt {
            let data = userData.assumingMemoryBound(to: UserData.self).pointee
            let (p1, p2, p3) = (data.p[0], data.p[1], data.p[2])
            
            let yyArray = N_VGetArrayPointer(yy)!
            let (y1, y2, y3) = (yyArray[0], yyArray[1], yyArray[2])
    
            let ypArray = N_VGetArrayPointer(yp)!
            let (yp1, yp2) = (ypArray[0], ypArray[1])
            
            let resArray = N_VGetArrayPointer(resval)!
            resArray[0] = yp1 + p1*y1 - p2*y2*y3
            resArray[1] = yp2 - p1*y1 + p2*y2*y3 + p3*y2*y2
            resArray[2] = y1 + y2 + y3 - 1

            return IDA_SUCCESS
        }

        func resS(Ns: CInt, t: realtype,
                  yy: N_Vector!, yp: N_Vector!, resval: N_Vector!,
                  yyS: UnsafeMutablePointer<N_Vector?>!,
                  ypS: UnsafeMutablePointer<N_Vector?>!,
                  resvalS: UnsafeMutablePointer<N_Vector?>!,
                  userData: UnsafeMutableRawPointer!,
                  tmp1: N_Vector!, tmp2: N_Vector!, tmp3: N_Vector!
        ) -> CInt {
            let NS = 3

            let data = userData.assumingMemoryBound(to: UserData.self).pointee
            let (p1, p2, p3) = (data.p[0], data.p[1], data.p[2])
            
            let yyArray = N_VGetArrayPointer(yy)!
            let (y1, y2, y3) = (yyArray[0], yyArray[1], yyArray[2])
            
            for i in 0 ..< NS {
                let ySArray = N_VGetArrayPointer(yyS![i])!
                let (s1, s2, s3) = (ySArray[0], ySArray[1], ySArray[2])

                let ypSArray = N_VGetArrayPointer(ypS![i])!
                let (sd1, sd2) = (ypSArray[0], ypSArray[1])

                var rs1 = sd1 + p1*s1 - p2*y3*s2 - p2*y2*s3
                var rs2 = sd2 - p1*s1 + p2*y3*s2 + p2*y2*s3 + 2*p3*y2*s2
                let rs3 = s1 + s2 + s3
                
                switch i {
                  case 0:
                    rs1 += y1
                    rs2 -= y1
                  case 1:
                    rs1 -= y2*y3
                    rs2 += y2*y3
                  case 2:
                    rs2 += y2*y2
                default:
                    break
                }
                
                let resvalSArray = N_VGetArrayPointer(resvalS[i])!
                resvalSArray[0] = rs1
                resvalSArray[1] = rs2
                resvalSArray[2] = rs3
            }
            
            return IDA_SUCCESS
        }
        
        func rhsQ(t: realtype, y: N_Vector!, yp: N_Vector!, ypQ: N_Vector!,
                  userData: UnsafeMutableRawPointer!
        ) -> CInt {
            let data = userData.assumingMemoryBound(to: UserData.self).pointee
            let coef = data.coef
            
            let yArray = N_VGetArrayPointer(y)!
            let (y1, y2, y3) = (yArray[0], yArray[1], yArray[2])

            let ypQArray = N_VGetArrayPointer(ypQ)!
            ypQArray[0] = y3
            ypQArray[1] = coef * (y1*y1 + y2*y2 + y3*y3)
            
            return IDA_SUCCESS
        }
    }
}

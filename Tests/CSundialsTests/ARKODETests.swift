import XCTest
import CSundials


final class ARKODETests: XCTestCase {
    static var allTests = [
        ("test_ark_analytic", test_ark_analytic),
        ("test_ark_robertson_root", test_ark_robertson_root)
    ]

    /// Solves a simple linear ODE equation.
    ///
    /// The following is a simple example problem with analytical solution,
    ///
    /// ```
    /// dy/dt = lambda*y + 1/(1 + t^2) - lambda*atan(t)
    /// ```
    ///
    /// for `t` in the interval `[0.0, 10.0]`, with initial condition: `y = 0`.
    ///
    /// The stiffness of the problem is directly proportional to the value of `lambda`.  The value of
    /// `lambda` should be negative to result in a well-posed ODE; for values with magnitude larger
    /// than 100 the problem becomes quite stiff.
    ///
    /// This program solves the problem with the DIRK method, Newton iteration with the dense linear
    /// solver and a user-supplied Jacobian routine.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/arkode/C_Serial/ark_analytic.c
    ///
    func test_ark_analytic() {
        let T0 = 0.0
        let Tf = 10.0
        let dTout = 1.0
        let NEQ: sunindextype = 1
        let reltol = 1e-6
        let abstol = 1e-10
        var lambda = -100.0

        // MARK: Setup

        let y = N_VNew_Serial(NEQ)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
        N_VConst(0.0, y)
        
        var arkodeMem = ARKStepCreate(nil, f, T0, y)
        XCTAssertNotNil(arkodeMem)
        defer { ARKStepFree(&arkodeMem) }
        
        var retval = ARKStepSetUserData(arkodeMem, &lambda)
        XCTAssertEqual(retval, ARK_SUCCESS)

        retval = ARKStepSStolerances(arkodeMem, reltol, abstol)
        XCTAssertEqual(retval, ARK_SUCCESS)

        let A = SUNDenseMatrix(NEQ, NEQ)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }

        let LS = SUNLinSol_Dense(y, A)
        XCTAssertNotNil(A)
        defer { SUNLinSolFree(LS) }

        retval = ARKStepSetLinearSolver(arkodeMem, LS, A)
        XCTAssertEqual(retval, ARK_SUCCESS)

        retval = ARKStepSetJacFn(arkodeMem, Jac)
        XCTAssertEqual(retval, ARK_SUCCESS)
        
        retval = ARKStepSetLinear(arkodeMem, 0)
        XCTAssertEqual(retval, ARK_SUCCESS)

        // MARK: Timestepping
        
        var t = T0
        var tout = T0 + dTout

        while (Tf - t) > 1.0e-15 {
            switch ARKStepEvolve(arkodeMem, tout, y, &t, ARK_NORMAL) {
            case ARK_SUCCESS:
                tout += dTout
                tout = (tout > Tf) ? Tf : tout
            default:
                XCTFail()
            }
        }

        // MARK: Verification

        let ans = N_VNew_Serial(NEQ)
        XCTAssertNotNil(ans)
        defer { N_VDestroy(ans) }
        let ansArray = N_VGetArrayPointer(ans)!
        ansArray[0] = atan(t)
        
        XCTAssertAlmostEqual(y, ans, reltol, abstol)

        // MARK: Problem

        func f(t: realtype, y: N_Vector!, ydot: N_Vector!,
               userData: UnsafeMutableRawPointer!) -> CInt {
            
            let lambda = userData.load(as: Double.self)
            let yArray = N_VGetArrayPointer(y)!
            let y = yArray[0]
            
            let yd = lambda * y + 1/(1 + t*t) - lambda * atan(t)
            
            let ydArray = N_VGetArrayPointer(ydot)!
            ydArray[0] = yd
            
            return ARK_SUCCESS
        }
        
        func Jac(t: realtype, y: N_Vector!, fy: N_Vector!, J: SUNMatrix!,
                 userData: UnsafeMutableRawPointer!,
                 tmp1: N_Vector!, tmp2: N_Vector!, tmp3: N_Vector!) -> CInt {

            let lambda = userData.load(as: Double.self)
            let JData = SUNDenseMatrix_Data(J)!
            JData[0] = lambda
            
            return ARK_SUCCESS
        }
    }
    
    /// Solves simple non-linear system of ODEs.
    ///
    /// The following test simulates the Robertson problem, corresponding to the kinetics of an
    /// autocatalytic reaction. The ODE is a system with 3 components `[u, v, w]` satisfying the
    /// equations,
    ///
    /// ```
    /// du/dt = -0.04*u + 1e4*v*w
    /// dv/dt = +0.04*u - 1e4*v*w - 3e7*v^2
    /// dw/dt = 3e7*v^2
    /// ```
    /// for `t` in the interval `[0, 1e11]`, with initial condition `y0 = [1,0,0]`.
    ///
    /// While integrating the system, we use the root-finding feature to find the times at which either
    /// `u = 1e-4` or `w = 1e-2`.
    ///
    /// This test solves the problem with ARK integrator.  Implicit subsystems are solved using a Newton
    /// iteration with the dense liner solver, and a user-supplied Jacobian routine.
    ///
    /// https://github.com/LLNL/sundials/blob/master/examples/arkode/C_serial/ark_robertson_root.c
    ///
    func test_ark_robertson_root() {
        let NEQ: sunindextype = 3
        let T0 = 0.0
        let T1 = 0.4
        let TMULT = 10.0
        let Nt = 12

        // MARK: Setup

        let y = N_VNew_Serial(NEQ)
        XCTAssertNotNil(y)
        defer { N_VDestroy(y) }
        let yArray = N_VGetArrayPointer(y)!
        yArray[0] = 1
        yArray[1] = 0
        yArray[2] = 0

        let reltol = 1e-4
        let atols = N_VNew_Serial(NEQ)
        XCTAssertNotNil(atols)
        defer { N_VDestroy(atols) }
        let atolsArray = N_VGetArrayPointer(atols)!
        atolsArray[0] = 1e-8
        atolsArray[1] = 1e-11
        atolsArray[2] = 1e-8
        
        var arkodeMem = ARKStepCreate(nil, f, T0, y)
        XCTAssertNotNil(arkodeMem)
        defer { ARKStepFree(&arkodeMem) }
        
        var flag = ARKStepSetMaxErrTestFails(arkodeMem, 20)
        XCTAssertEqual(flag, ARK_SUCCESS)
        flag = ARKStepSetMaxNonlinIters(arkodeMem, 8)
        XCTAssertEqual(flag, ARK_SUCCESS)
        flag = ARKStepSetNonlinConvCoef(arkodeMem, 1e-7)
        XCTAssertEqual(flag, ARK_SUCCESS)
        flag = ARKStepSetMaxNumSteps(arkodeMem, 100_000)
        XCTAssertEqual(flag, ARK_SUCCESS)
        flag = ARKStepSetPredictorMethod(arkodeMem, 1)
        XCTAssertEqual(flag, ARK_SUCCESS)
        flag = ARKStepSVtolerances(arkodeMem, reltol, atols)
        XCTAssertEqual(flag, ARK_SUCCESS)

        flag = ARKStepRootInit(arkodeMem, 2, g)
        XCTAssertEqual(flag, ARK_SUCCESS)

        let A = SUNDenseMatrix(NEQ, NEQ)
        XCTAssertNotNil(A)
        defer { SUNMatDestroy(A) }

        let LS = SUNLinSol_Dense(y, A)
        XCTAssertNotNil(LS)
        defer { SUNLinSolFree(LS) }

        flag = ARKStepSetLinearSolver(arkodeMem, LS, A)
        XCTAssertEqual(flag, ARK_SUCCESS)

        flag = ARKStepSetJacFn(arkodeMem, Jac)
        XCTAssertEqual(flag, ARK_SUCCESS)

        // MARK: Timestepping
        
        var iout = 1
        var tout = T1
        var t: realtype = 0.0
        
        while iout <= Nt {
            switch ARKStepEvolve(arkodeMem, tout, y, &t, ARK_NORMAL) {
            case ARK_SUCCESS:
                iout += 1
                tout *= TMULT

            case ARK_ROOT_RETURN:
                var roots: (CInt, CInt) = (0, 0)
                flag = ARKStepGetRootInfo(arkodeMem, &roots.0)
                XCTAssertEqual(flag, ARK_SUCCESS)

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

        N_VScale(10, atols, atols)
        XCTAssertAlmostEqual(y, ref, reltol, atols)
        
        // MARK: Problem

        func f(t: realtype, y: N_Vector!, ydot: N_Vector!,
               userData: UnsafeMutableRawPointer?) -> CInt {
            
            let yArray = N_VGetArrayPointer(y)!
            let (u, v, w) = (yArray[0], yArray[1], yArray[2])
            
            let du = -0.04 * u + 1e4 * v * w
            let dv = +0.04 * u - 1e4 * v * w - 3e7 * v * v
            let dw = 3e7 * v * v
            
            let ydotArray = N_VGetArrayPointer(ydot)!
            (ydotArray[0], ydotArray[1], ydotArray[2]) = (du, dv, dw)
            
            return ARK_SUCCESS
        }

        func g(t: realtype, y: N_Vector!, gout: UnsafeMutablePointer<realtype>!,
               userData: UnsafeMutableRawPointer?) -> CInt {
            let yArray = N_VGetArrayPointer(y)!
            let (u, w) = (yArray[0], yArray[2])
            
            gout[0] = u - 0.0001
            gout[1] = w - 0.01

            return ARK_SUCCESS
        }
        
        func Jac(t: realtype, y: N_Vector!, fy: N_Vector!, J: SUNMatrix!,
                 userData: UnsafeMutableRawPointer?,
                 tmp1: N_Vector!, tmp2: N_Vector!, tmp3: N_Vector!) -> CInt {
            
            let yArray = N_VGetArrayPointer(y)!
            let (v, w) = (yArray[1], yArray[2])

            let JCols = SUNDenseMatrix_Cols(J)!
            JCols[0]![0] = -0.04
            JCols[1]![0] = 1e4 * w
            JCols[2]![0] = 1e4 * v
            
            JCols[0]![1] = 0.04
            JCols[1]![1] = -1e4 * w - 6e7 * v
            JCols[2]![1] = -1e4 * v
            
            JCols[0]![2] = 0.0
            JCols[1]![2] = 6e7 * v
            JCols[2]![2] = 0.0

            return ARK_SUCCESS
        }
    }
}

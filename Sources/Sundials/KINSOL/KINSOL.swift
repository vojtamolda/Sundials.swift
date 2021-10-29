import CSundials
import CSundials_KINSOL_Private


/// General-purpose nonlinear algebraic equation solver based on Newton-Krylov technology.
///
/// _KINSOL_ solves nonlinear algebraic systems in real `D`-dimensional space. In other words, it allows
/// one to solve the following equation and find `u` such that
///
/// ```
/// F(u) = 0,
/// ```
///
/// for an arbitrarily complicated user defined function `F`.
public class KINSOL: Solver {
    var mem: KINMem
    
    public typealias Solution = Vector

    /// Global solution strategy of the algebraic equation system.
    public var strategy: Strategy

    /// Solver for the Jacobian system of linear equations.
    ///
    /// - Important: A linear solver is required, i.e. can't be `nil`, by all global solution strategies
    /// except ``Strategy-swift.enum/fixedPointIteration``.
    public var linearSolver: SUNLinearSolver? = nil
    
    /// Scaled function norm stopping tolerance.
    ///
    /// This property specifies the scalar used as a stopping tolerance on the scaled maximum
    /// norm of the system function `F`. More precisely, the solution `uN` is assumed to be converged if
    ///
    /// ```
    /// max(|F(uN)| * fScale) < systemNormStoppingTolerance.
    /// ```
    ///
    /// - Note: The default value is `realtype.ulpOfOne^(1/3)`.
    /// - Warning: Tolerance must be positive, i.e. > 0. Otherwise, setting the value is ignored.
    public var stoppingTolerance: realtype {
        get { mem.pointee.kin_fnormtol }
        set { KINSetFuncNormTol(mem, newValue) }
    }

    /// Scaled step norm stopping tolerance.
    ///
    /// This property specifies the scalar used as a stopping tolerance on the minimum scaled step length.
    /// More precisely, the solution `uN` is assumed to be converged if
    ///
    /// ```
    /// max(|uN+1 − uN| * fScale) < stepStoppingTolerance.
    /// ```
    ///
    /// - Note: The default value is `realtype.ulpOfOne^(2/3)`.
    /// - Warning: Tolerance must be positive, i.e. > 0. Otherwise, setting the value is ignored.
    public var stepStoppingTolerance: realtype {
        get { mem.pointee.kin_sthrsh }
        set { KINSetScaledStepTol(mem, newValue) }
    }
    
    /// Creates a solver instance that uses the specified global solution strategy.
    ///
    /// - Parameters:
    ///   - strategy: Global solution strategy that will be used to find solutions to
    ///   algebraic problems.
    public init(strategy: Strategy) {
        let mem = KINCreate()
        precondition(mem != nil, "KINCreate() failed.")
        self.mem = mem!.assumingMemoryBound(to: KINMemRec.self)
        self.strategy = strategy
    }
    
    /// Starts solving the algebraic equation system from the initial guess and returns the solution.
    ///
    /// - Parameters:
    ///   - problem: System with algebraic equations possibly with constraints.
    ///   - initialGuess: Initial guess to start the iterative solution process. For systems with
    ///   multiple solutions, a different initial guess will lead the solver, in general, to a different solution.
    ///
    /// - Returns: Solution of the algebraic equation system if the solution strategy converged.
    ///
    /// - Throws: Failure when the solution didn't happen.
    public func solve(
        problem: AlgebraicProblem, initialGuess: Solution) throws
    -> Solution {
        var flag: Int32
        
        struct Err {
            let errorCode: Int
            let module, function, message: String
            
            init(_ errorCode: Int32,
                 _ module: UnsafePointer<CChar>?,
                 _ function: UnsafePointer<CChar>?,
                 _ message: UnsafePointer<CChar>?)
            {
                self.errorCode = Int(errorCode)
                self.module = String(cString: module!)
                self.function = String(cString: function!)
                self.message = String(cString: message!)
            }
        }

        //        var err: Err? = nil
//
//        let cErr: KINErrHandlerFn = { flag, module, function, message, data in
//            err = Err(flag, module, function, message)
//        }
//        KINSetErrHandlerFn(mem, cErr, nil)

        let cSystem: KINSysFn = { uPointer, fPointer, userData in
            assert(uPointer != nil && fPointer != nil && userData != nil)
            let problemClosures = userData!.assumingMemoryBound(
                to: AlgebraicProblem.Closures.self).pointee

            let u = Vector(borrow: uPointer!)
            var f = Vector(borrow: fPointer!)
            do {
                try problemClosures.system(u, &f)
                return KIN_SUCCESS
            } catch {
                return 1
            }
        }

        var u = initialGuess
        flag = KINInit(mem, cSystem, u.mutablePointer)
        if let failure = Failure(rawValue: flag) { throw failure }

        var closures = problem.closures
        flag = KINSetUserData(mem, &(closures))
        if let failure = Failure(rawValue: flag) { throw failure }
        
        if let constraints = problem.constraints {
            let rawConstraints = Vector(copy: constraints.map(\.rawValue))
            flag = KINSetConstraints(mem, rawConstraints.pointer)
            if let failure = Failure(rawValue: flag) { throw failure }
        }
        
        if linearSolver != nil {
            // TODO: Figure out where to get J from!
            //flag = KINSetLinearSolver(mem, linearSolver, problem.J)
            //if let failure = Failure(rawValue: flag) { throw failure }
        }
        
        var fScale: Vector
        if problem.fScale == nil {
            // TODO: Rewrite in a higher-level API
            let fScaleVec = N_VClone(initialGuess.pointer)!
            N_VConst(1, fScaleVec)
            fScale = Vector(manage: fScaleVec)
        } else {
            fScale = problem.fScale!
        }
        
        var uScale: Vector
        if problem.uScale == nil {
            // TODO: Rewrite in a higher-level API
            let uScaleVec = N_VClone(initialGuess.pointer)!
            N_VConst(1, uScaleVec)
            uScale = Vector(manage: uScaleVec)
        } else {
            uScale = problem.uScale!
        }

        flag = KINSol(mem, u.mutablePointer, strategy.rawValue,
                      uScale.pointer, fScale.pointer)
        if let failure = Failure(rawValue: flag) {
            throw failure
        }
        
        return u
    }
    
    deinit {
        //var optionalMem = mem as UnsafeMutableRawPointer?
        //KINFree(&mem)
    }
}




public protocol Solver: AnyObject {
    associatedtype AlgebraicProblem
    associatedtype Solution
    
    func solve(problem: AlgebraicProblem, initialGuess: Solution) throws -> Solution
}




public struct NoLinearSolver: LinearSolver {
    
}

public protocol LinearSolver {
    
}

extension KINSOL {
    
    /// Definition of a problem formulated as an algebraic system of equations.
    ///
    /// This struct is a collection of objects that define a system of algebraic equations in a form that is
    /// solvable by _KINSOL_. There are members for specifications of the RHS
    ///
    /// 
    public struct AlgebraicProblem {
        
        /// Function evaluating residuum of the algebraic system of equations.
        ///
        /// This user supplied function is representation of the problem defining function `F(u)` (or
        /// `G(u)`  for some solution strategies). Given a solution vector `u` it evaluates `F(u)`.
        /// Alternatively, the return value can also be viewed as a residuum, i.e. difference from 0, of
        /// the algebraic equation system `F(u) = 0`.
        ///
        /// - Parameters:
        ///   - u: Current solution iterate.
        ///
        /// - Returns: Equation system evaluated at the current solution via an inout parameter
        ///  (performance optimization).
        ///
        /// - Throws: ``SystemFailure/recoverableError`` when a recoverable error has
        ///  happened. _KINSOL_ solver will retry several times with a smaller steps.
        ///  ``SystemFailure/terminalError`` when there is a serious problem during the
        ///  function evaluation.
        public typealias System = (
            _ u: Vector, _ f: inout Vector
        ) throws -> Void
        public var system: System
        
        /// Function evaluating Jacobian matrix of the algebraic system of equations.
        ///
        /// - Parameters:
        ///   - u: Current solution iterate.
        ///   - f: Current residuum of the system.
        ///
        ///  - Returns: Jacobian of the equation system evaluated at the current solution via
        ///  an inout parameter (performance optimization).
        ///
        /// - Throws: ``SystemFailure/recoverableError`` when a recoverable error has
        ///  happened. _KINSOL_ solver will retry several times with a smaller steps.
        ///  ``SystemFailure/terminalError`` when there is a serious problem during the
        ///  function evaluation.
        public typealias Jacobian = (
            _ u: Vector, _ f: Vector, _ J: inout Matrix
        ) throws -> Void
        /// Function evaluating Jacobian of the equation system.
        public var jacobian: Jacobian?
        
        /// Function evaluating product of the system Jacobian matrix and a vector.
        ///
        /// - Parameters:
        ///   - u: Current solution iterate.
        ///   - f: Current residuum of the system.
        ///   - v: Vector to be left-multiplied by the Jacobian.
        ///
        /// - Returns:
        /// Jacobian vector product `J(u)•v` via an inout parameter (performance optimization).
        ///
        /// - Throws: ``SystemFailure/recoverableError`` when a recoverable error has
        ///  happened. _KINSOL_ solver will retry several times with a smaller steps.
        ///  ``SystemFailure/terminalError`` when there is a serious problem during the
        ///  function evaluation.
        public typealias JVP = (
            _ u: Vector, _ f: Vector, _ v: Vector, _ JVP: inout Vector
        ) throws -> Void
        /// Function evaluating Jacobian vector product.
        public var jvp: JVP?
        
        public enum SystemFailure: Error {
            case recoverableError
            case terminalError
        }

        /// Workaround for passing Swift closures to C as function pointers.
        ///
        /// An instance of this struct is passed as user data `void *` pointer. This pointer is then
        /// available in to every user defined function.
        struct Closures {
            let system: System
            let jacobian: Jacobian?
            let jvp: JVP?
        }
        /// Storage of Swift closures for use in C APIs.
        var closures: Closures {
            Closures(system: system, jacobian: jacobian, jvp: jvp)
        }
        
        /// Representation of a constraint imposed on a component of solution  `u`.
        public enum Constraint: Double, RawRepresentable {
            /// No constraint is imposed on the corresponding component of solution `u`.
            case none = 0.0
            /// Corresponding component of solution `u` is constrained to `u[i] >= 0`.
            case positive = 1.0
            /// Corresponding component of solution `u` is constrained to `u[i] =< 0`.
            case negative = -1.0
            /// Corresponding component of solution `u` is constrained to `u[i] > 0`.
            case strictlyPositive = 2.0
            /// Corresponding component of solution `u` is constrained to `u[i] < 0`.
            case strictlyNegative = -2.0
        }
        /// Constraints imposed on corresponding components of solution `u`.
        public var constraints: [Constraint]? = nil
        
        /// Scaling factors of solution vector `u` near the root.
        ///
        /// Scaling values should be chosen such that when element-wise multiplied with `u` all
        /// components have roughly the same magnitude near the root of `F(u)`.
        ///
        /// - Important: All components should be strictly positive.
        public var uScale: Vector? = nil

        /// Scaling factors of  RHS vector `f` far from the root.
        ///
        /// Scaling values should be chosen such that when element-wise multiplied with `f` all
        /// components have roughly the same magnitude far away from the root of `F(u)`.
        ///
        /// - Important: All components should be strictly positive.
        public var fScale: Vector? = nil
        
        public init(system: @escaping System) {
            self.system = system
            self.jacobian = nil
            self.jvp = nil
        }
    }
}

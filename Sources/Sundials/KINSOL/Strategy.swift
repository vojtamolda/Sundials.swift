import CSundials


extension KINSOL {

    /// Global solution strategy of an algebraic system of equations.
    public enum Strategy: Int32, RawRepresentable {
        /// Basic Newton iteration.
        ///
        /// This algorithm implements an iterative method to find roots of a differentiable function `F`.
        /// The key idea is to fit a local parabola at the current solution candidate and then proceed to the
        /// minimum of the parabola for the next iteration.
        ///
        /// See [Wikipedia][Newton's Method] for more details.
        ///
        /// - Note: Linear solver is required.
        ///
        /// [Newton's Method]: https://en.wikipedia.org/wiki/Newton%27s_method_in_optimization
        case newtonsMethod
        
        /// Newton iteration with backtracking line search.
        ///
        /// This solution strategy implements a search scheme based on Armijo–Goldstein condition that
        /// determines the amount to move along the Newton method determined search direction.
        ///
        /// See [Wikipedia][Line Search] for more details.
        ///
        /// - Note: Linear solver is required.
        ///
        /// [Line Search]: https://en.wikipedia.org/wiki/Backtracking_line_search
        ///
        case backtrackingLineSearch
        
        /// Picard iteration with Anderson Acceleration.
        ///
        /// This solution strategy implements a modified version of the fixed point iteration for a special
        /// case of the nonlinear function `F(u)`.
        ///
        /// See [guide][Guide] for more details. [This page][Anderson acceleration] has more
        /// details about the Anderson acceleration trick.
        ///
        /// - Note: Linear solver is required. Constraints are not supported.
        /// 
        /// [Guide]: https://github.com/LLNL/sundials/blob/master/doc/kinsol/kin_guide.pdf
        /// [Anderson acceleration]: https://en.wikipedia.org/wiki/Anderson_acceleration
        case picardIteration
        
        /// Fixed-point iteration with Anderson acceleration.
        ///
        /// This solution strategy repeatedly applies the nonlinear function `G` to the current iterate to
        /// produce the following one. Key requirement is that the nonlinear function `G` is a contraction
        /// in the Banach space of solutions. Contractive functions gradually shrink the distance
        /// between the current iteration and the root, thus achieving convergence when `G(u) = u`.
        ///
        /// See [Wikipedia][Fixed-point iteration] for the mathematical details.
        /// [This page][Anderson acceleration] has more details about the Anderson acceleration trick.
        ///
        /// - Note: Linear solver isn't required. Constraints are not supported.
        ///
        /// [Fixed-point Iteration]: https://en.wikipedia.org/wiki/Fixed-point_iteration
        /// [Anderson acceleration]: https://en.wikipedia.org/wiki/Anderson_acceleration
        case fixedPointIteration
        
        /// Raw numeric value used in C API.
        public var rawValue: Int32 {
            switch self {
            case .newtonsMethod:
                return KIN_NONE
            case .backtrackingLineSearch:
                return KIN_LINESEARCH
            case .picardIteration:
                return KIN_PICARD
            case .fixedPointIteration:
                return KIN_FP
            }
        }
        
        /// Creates an instance from a raw numeric value used in C API.
        public init?(rawValue: Int32) {
            switch rawValue {
            case KIN_NONE:
                self = .newtonsMethod
            case KIN_LINESEARCH:
                self = .backtrackingLineSearch
            case KIN_PICARD:
                self = .picardIteration
            case KIN_FP:
                self = .fixedPointIteration
            default:
                return nil
            }
        }
    }

}

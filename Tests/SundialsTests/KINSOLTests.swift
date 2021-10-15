import XCTest
import Foundation
import Sundials


final class KINSOLTests: XCTestCase {
    static var allTests = [
        ("testFerrarisTronconi", testFerrarisTronconi),
    ]
    
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
    func testFerrarisTronconi() {
        let (range1, range2) = (0.25...1.0, 1.5...(2.0 * .pi))

        var problem = KINSOL.AlgebraicProblem { u, f in
            let (x1, x2) = (u[0], u[1])
            let (l1, L1) = (u[2], u[3])
            let (l2, L2) = (u[4], u[5])
            let (e, pi) = (exp(1.0), Double.pi)
            
            f[0] = 0.5 * sin(x1*x2) - 0.25 * x2/pi - 0.5*x1
            f[1] = (1 - 0.25/pi) * (exp(2*x1) - e) + e*x2/pi - 2*e*x1
            f[2] = l1 - x1 + range1.lowerBound
            f[3] = L1 - x1 + range1.upperBound
            f[4] = l2 - x2 + range2.lowerBound
            f[5] = L2 - x2 + range2.upperBound
        }
        
        problem.constraints = [
            .none, // x1
            .none, // x2
            .positive, // l1
            .negative, // L1
            .positive, // l2
            .negative // L2
        ]

        var (x1, x2) = (range1.upperBound, range2.lowerBound)
        let u1: Vector = [ // Guess close to [0.29945, 2.83693]
            x1, // x1
            x2, // x2
            x1 - range1.lowerBound, // l1
            x1 - range1.upperBound, // L1
            x2 - range2.lowerBound, // l2
            x2 - range2.upperBound, // L2
        ]
        
        (x1, x2) = (range1.upperBound, range2.lowerBound)
        let u2: Vector = [ // Guess close to [1/2, pi]
            x1, // x1
            x2, // x2
            x1 - range1.lowerBound, // l1
            x1 - range1.upperBound, // L1
            x2 - range2.lowerBound, // l2
            x2 - range2.upperBound, // L2
        ]
        
        let solver = KINSOL(strategy: .newtonsMethod)

        let solution = try? solver.solve(problem: problem, initialGuess: u1)
        
        print(solution!)
    }
    
    func testIntegrity() {
        let kinsol = KINSOL(strategy: .fixedPointIteration)
        
        kinsol.checkSetGet(\.stoppingTolerance, to: 1e-5)
        kinsol.checkSetGet(\.stepStoppingTolerance, to: 1e-6)
    }
}


extension KINSOL {
    /// Writes and reads a property to verify its `get` and `set` methods.
    func checkSetGet<T>(
        _ property: ReferenceWritableKeyPath<KINSOL, T>, to value: T
    ) where T: Equatable {
        self[keyPath: property] = value
        XCTAssertEqual(self[keyPath: property], value)
    }
}

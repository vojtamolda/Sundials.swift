# ``Sundials/KINSOL``


## Solution Strategies

The following paragraphs describe the means how to obtain solution of the algebraic system. Choosing the solution strategy is the most important decision one does when solving an algebraic system. It is specified via the ``strategy-swift.property`` property.


### Fixed Point Iteration

Using the fixed-point iteration, given an initial guess, one can solve

```
G(u) = u,   G: R^D → R^D.
```

The basic fixed-point iteration scheme implemented in ``Strategy-swift.enum/fixedPointIteration`` is given by:

1. Set `u0` to an initial guess and `N` to 0.
2. Set `uN+1 = (1 − β)*uN + β*G(uN)`
3. Increment `N` and go to 2. unless converged

Here, `uN` is the N-th iterate to `u`.  At each stage in the iteration process, the function `G` is applied to the current iterate with the damping parameter `β` to produce a new iterate, `uN+1`. A test for convergence is made before the iteration continues.

The fixed point iteration can be significantly accelerated using Anderson’s method. For more details about it's implementation and mathematical formulation see [guide][Guide].

### Newton Iteration and Backtracking Line Search

Using the Newton’s method, or the Backtracking line search algorithm, given an initial guess, one can solve

```
F(u) = 0,   F: R^D → R^D.
```

Depending on the used linear solver, _KINSOL_ can employ either an Inexact Newton method, or a Modified Newton method. At the highest level, the solver implements the following iteration scheme:

1. Set `u0` to an initial guess and `N` to 0.
3. Solve linear system given by `J(uN)•δN = −F(uN)`.
4. Set `uN+1 = uN + λ*δN`, where `0 < λ ≤ 1`.
3. Increment `N` and go to 2. unless converged

Here, `uN` is the N-th iterate to `u`, and `J(u) = F′(u)` is the Jacobian matrix of the system. At each stage in the iteration process, a scalar multiple of the step `δN`, is added to `uN` to produce a new iterate, `uN+1`. A test for convergence is made before the iteration continues.

For modified Newton iteration option, ``Strategy-swift.enum/newtonsMethod``, the value of `λ` is always set to 1. ``Strategy-swift.enum/backtrackingLineSearch`` option, however, implements a smart backtracking algorithm to first find the value `λ` such that `uN + λδN` satisfies the sufficient decrease condition. The goal is to use the direction implied by δN in the most efficient way for furthering convergence of the nonlinear problem. For more details, please, see [guide][Guide].


### Picard Iteration

For Picard iteration, as implemented in ``Strategy-swift.enum/picardIteration``, consider a special form of the nonlinear function
`F` , such that

```
F(u) = L•u − M(u),
```

where `L` is a constant nonsingular matrix and `M` is (in general) nonlinear. The fixed-point function `G` is then defined as `G(u) = u − inv(L)•F(u)`.

The Picard iteration algorithm is given by:

1. Set `u0` to an initial guess and `N` to 0.
2. Set `uN+1 = (1 − β)*uN + β*G(uN)` where `G(uN) = uN − inv(L)•F(uN)`.
3. Test `F(uN+1)` for convergence. Increment `N` and go to 2. if not converged.

Here, `uN` is the N-th iterate to `u`.  Within each iteration, the Picard step is computed then added to `uN` with the damping parameter `β` to produce the new iterate. Next, the nonlinear residual function is evaluated at the new iterate, and convergence is checked.

Noting that `inv(L)•M(u) = u − inv(L)•F(u)`, the above iteration can be written in the same form as a Newton iteration except that here, `L` is in the role of the Jacobian. Within _KINSOL_, however, the fixed-point form as above is used.

The Picard iteration can be significantly accelerated using Anderson’s method. For more details about it's implementation and mathematical formulation see [guide][Guide].


## Convergence Criteria

The algebraic equation system is almost never solved exactly, e.g there's virtually always a residuum, an error present in the numerical solution. Setting the tolerances and scaling correctly allows one to make the right tradeoff between solution accuracy and speed.


### Fixed Point Iteration Stopping Criterion

The default stopping criterion is based on the difference between two subsequent steps being smaller then ``stepStoppingTolerance``

```
max(|uN+1 − uN| * fScale) < stepStoppingTolerance,
```

where ``AlgebraicProblem/fScale`` is a user-defined scaling vector chosen so that the components of `fScale*(G(u) − u)` have roughly the same order of magnitude. Note that when using Anderson acceleration, convergence is checked after the acceleration is applied. The scaling is particularly useful to address ill-conditioned nonlinear systems.


### Picard Iteration Stopping Criterion

The default stopping criterion is based on the error being smaller than ``stoppingTolerance``

```
max(|F(uN)| * fScale) < stoppingTolerance,
```

where ``AlgebraicProblem/fScale`` is a user-defined scaling vector chosen so that the components of `fScale*F(u)` have roughly the same order of magnitude. Note that when using Anderson acceleration, convergence is checked after the acceleration is applied. The scaling is particularly useful to address ill-conditioned nonlinear systems.


## Other Resources

See [guide][Guide] for a exact mathematical considerations and details about the implementation. Alternatively, [commented C examples][Examples] can be a good source of information if you are more practically inclined.

If all else fails, one can always read the [source code][Source] of the wrapped C library.


## Topics

### Problem Definition

- ``AlgebraicProblem``

### Solver Options

- ``Strategy-swift.enum``

### Linear Solver

- ``LinearSolver``





[Guide]: https://github.com/LLNL/sundials/blob/master/doc/kinsol/kin_guide.pdf
[Examples]: https://github.com/LLNL/sundials/blob/master/doc/kinsol/kin_examples.pdf
[Source]: https://github.com/LLNL/sundials 

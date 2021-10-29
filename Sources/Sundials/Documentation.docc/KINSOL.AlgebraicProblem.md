# ``Sundials/KINSOL/AlgebraicProblem``


## Overview

TODO: Describe ho to use the ``System-swift.typealias`` closure.


## Jacobian Approximations

With the dense and banded matrix-based linear solvers, the Jacobian may be supplied by a user routine, or approximated by difference quotients, at the user’s option.

In the latter case, we use the usual approximation

```
J[i,j] ≈ ( (F[i](u + σ[j]•e[j]) − F[i](u) ) / σ[j].
```

The components of the increment `σ[j]` are given by

```
σ[j] = √U * max{|u[j]|, 1/uScale[j]}.
```

In the dense case, this scheme requires one evaluations of `F` for each column of `J`. In the band case, the columns of `J` are computed in groups, by the Curtis-Powell-Reid algorithm, with the number of `F` evaluations equal to the bandwidth. The parameter `U` above can (optionally) be replaced by a user-specified value, `relfunc`.

Note that with sparse and user-supplied matrix-based linear solvers, the Jacobian evaluation closure must be supplied to the problem, i.e. it is not approximated internally with difference quotients.

In the case of a matrix-free iterative linear solver, Jacobian information is needed only as matrix-vector products `J•v`. If a routine for `J•v` is not supplied, these products are approximated by directional difference quotients as

```
J(u)•v ≈ (F(u + σv) − F(u)) / σ
```

where `u` is the current approximation of the solution, and `σ` is a scalar. The choice of `σ` is given by

```
σ = ( max{|u•v|, utyp•|v|} / (|v|*|v|) ) * sign(u•v) * √U
```

where `utyp` is a vector of typical values for the absolute values of the solution (and can be taken to be inverses of the scale factors ``uScale`` given for `u` as described below). This formula is also suitable for scaled vectors `u` and `v`.

The parameter `U` above can (optionally) be replaced by a user-specified value, `relfunc`. Convergence of the Newton method is maintained as long as the value of `σ` remains appropriately small.


## Constraints

If a solution strategy based on the Newton's method is used, that is either ``Strategy-swift.enum/newtonsMethod`` or ``Strategy-swift.enum/backtrackingLineSearch``, _KINSOL_ permits application of inequality constraints via the ``constraints`` property. Both `u[i] > 0` and `u[i] < 0`, as well as `u[i] ≥ 0` and `u[i] ≤ 0` type of constraints are supported, where `u[i]` is the `i`-th component of solution vector `u`. Any such constraint, or no constraint, may be imposed on each component of `u`. 

The solver will reduce step lengths in order to ensure that no constraint is violated. Specifically, if a new Newton iterate will violate a constraint, the step length is scaled down. The maximum step length along the Newton direction that will satisfy all constraints is found and used instead.

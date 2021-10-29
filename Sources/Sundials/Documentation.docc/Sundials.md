# ``Sundials``

**SU**ite of **N**onlinear and **DI**fferential/**AL**gebraic equation **S**olvers.



## Overview

Sundials.swift library is designed and created with two high level goals in mind. First, to provide user friendly and performant wrappers around the [original library][Sundials] written in C. And second, leverage the [automatic differentiation][Differentiable Programming] built into the Swift compiler to automatically synthesize full Jacobians or Jacobian-vector products.

![Sundials](Sundials.jpg) <!-- https://unsplash.com/photos/cJLokI4adx8 -->


## Solvers

The suite consists of the following packages for solving different classes of equations. `f1`, `f2` and `f` are arbitrary, user supplied functions that define the problem. `y` is the solution vector and `y'` its derivative. `t` represents time and `y0` is the initial value of the solution. `p` is parameter vector used in solvers with the sensitivity capability.


### ARKODE

For integration of stiff, nonstiff, and multirate ordinary differential equation systems (ODEs) of the form

```
M•y' = f1(t,y) + f2(t,y), y(t0) = y0.
```


### CVODE(S)

For integration of stiff and nonstiff ordinary differential equation systems (ODEs) of the form

```
y' = f(t,y), y(t0) = y0.
```

The S stands for sensitivity and allows for optional (forward and adjoint)  analysis of the form

```
y' = f(t,y,p), y(t0) = y0(p).
```


### IDA(S)

For integration of differential-algebraic equation systems (DAEs) of the form

```
f(t,y,y') = 0, y(t0) = y0, y'(t0) = y0'.
```

The S stands for sensitivity and allows for optional (forward and adjoint)  analysis of the form

```
f(t,y,y',p) = 0, y(t0) = y0(p), y'(t0) = y0'(p).
```


### KINSOL

For solution of nonlinear algebraic equation systems of the form

```
f(y) = 0.
```


## Design

The general, high-level, philosophy of the library is to split the monolithic design of the C API into 3 separate pieces with appropriate abstractions.

There's the problem abstraction that describes what needs to be solved. Then there are the solvers specifying solution method and accuracy. And finally, a solution the solver arrived at. It represents the answer and the reason why one would use this library in the first place.


[Sundials]: https://computing.llnl.gov/projects/sundials
[Differentiable Programming]: https://github.com/apple/swift/blob/main/docs/DifferentiableProgramming.md


## Topics

### Solvers

- ``ARKODE``
- ``CVODES``
- ``IDAS``
- ``KINSOL``

### Problems

- ``ARKODE/InitialValueProblem``
- ``CVODES/InitialValueProblem``
- ``IDAS/InitialValueProblem``
- ``KINSOL/AlgebraicProblem``

### Solutions

- ``AKODE/Solution``
- ``CVODES/Solution``
- ``IDAS/Solution``
- ``KINSOL/Solution``

### Linear Algebra

- ``Vector``
- ``Matrix``
- ``LinearSolver``

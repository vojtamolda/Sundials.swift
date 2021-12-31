<img src="https://computing.llnl.gov/sites/default/files/styles/large/public/2021-02/sundials_logo_higher_contrast.png" alt="Sundials" align="right">


# Sundials.swift


[![Build Badge]][Build]  [![Release Badge]][Release]  [![Contributions Badge]][Contributions]
[![License Badge]][License]  [![Lifecycle Badge]][Lifecycle]  [![Swift Badge]][Swift]

> Currently it is impossible to complete the project to a bug that crashes the Swift compiler when inline closures are used. See https://bugs.swift.org/browse/SR-12992 for more details.


**SU**ite of **N**onlinear and **DI**fferential/**AL**gebraic equation **S**olvers wrapped for use in Swift. This library is designed and created with two high level goals in mind. First, to provide user friendly and performant wrappers around the [original library][Sundials] written in C. And second, leverage the [automatic differentiation][Differentiable Programming] built into the Swift compiler to automatically synthesize full Jacobians or Jacobian-vector products.

## Solvers

The suite consists of the following packages. The checkbox indicate whether it has already been wrapped for use in Swift. Unwrapped solvers can still use the original C API.

- [ ] **ARKODE** - for integration of stiff, nonstiff, and multirate ordinary differential equation systems (ODEs) of the form

  ``` M y' = f1(t,y) + f2(t,y), y(t0) = y0 ```.

- [ ] **CVODE** - for integration of stiff and nonstiff ordinary differential equation systems (ODEs) of the form

  ``` y' = f(t,y), y(t0) = y0 ```.

- [ ] **CVODES** - for integration and sensitivity analysis (forward and adjoint) of ordinary differential equation systems (ODEs) of the form

  ``` y' = f(t,y,p), y(t0) = y0(p) ```.

- [ ] **IDA** - for integration of differential-algebraic equation systems (DAEs) of the form

  ``` f(t,y,y') = 0, y(t0) = y0, y'(t0) = y0' ```.

- [ ] **IDAS** - for integration and sensitivity analysis (forward and adjoint) of differential-algebraic equation systems (DAEs) of the form

  ``` f(t,y,y',p) = 0, y(t0) = y0(p), y'(t0) = y0'(p) ```.

- [ ] **KINSOL** - for solution of nonlinear algebraic systems of the form

  ``` f(y) = 0 ```.

In the preceding equations `f1`, `f2` and `f` are arbitrary, user supplied functions that define the problem. `y` is the solution vector and `y'` its derivative. `t` represents time and `y0` is the initial value of the solution. `p` represents parameters used in adjoint solvers. 


## Example

```swift
import Sundials

// TODO: Write an example
```


## Installation

Library uses [Swift Package Manager] for distribution, building, running and testing. To bundle the library and solve problems in your own project, add the following dependency to your `Package.swift` manifest.

```swift
dependencies: [
    .package(url: "https://github.com/vojtamolda/Sundials.swift.git", .branch("main")),
]
```


## Documentation

Full reference user documentation can be found [here][Reference Documentation]. Text is talking about the original C version but the translation is relatively straightforward.

Public interface of the library follows the [Swift API Design Guidelines]. Primary design goal is to provide a beautiful API that can quickly solve a problem without compromising more advanced use cases.


## Release

This library is alpha software under active development. Expect crashes and problems. Elements the API are going to change in the future and some implementations are not tested. The recommendation is to depend on an exact commit to make sure your code doesn't break later.

If you are interested in contributing to the library, please feel free to open a [pull request][Sundials.swift PRs]
or report an [issue][Sundials.swift Issues].

Licensed under the BSD 3-Clause license. See [the text][License] for more details.



[Build Badge]: https://img.shields.io/github/workflow/status/vojtamolda/Sundials.swift/Package.svg "Build"
[Build]: https://github.com/vojtamolda/Sundials.swift/actions

[Release Badge]: https://img.shields.io/github/v/release/vojtamolda/Sundials.swift.svg?color=lightgrey "Release"
[Release]: https://github.com/vojtamolda/Sundials.swift/releases

[Contributions Badge]: https://img.shields.io/badge/contributions-welcome-blueviolet.svg "Contributions Welcome"
[Contributions]: https://github.com/vojtamolda/Sundials.swift/issues

[License Badge]: https://img.shields.io/github/license/vojtamolda/Sundials.swift.svg?color=yellow "BSD-3 Clause"
[License]: https://github.com/vojtamolda/Sundials.swift/blob/main/License.txt

[Lifecycle Badge]: https://img.shields.io/badge/lifecycle-maturing-blue.svg "Lifecycle"
[Lifecycle]: https://www.tidyverse.org/lifecycle/#maturing

[Swift Badge]: https://img.shields.io/badge/swift-5-orange.svg "Swift 5"
[Swift]: https://swift.org/blog/swift-5-released/


[Sundials]: https://computing.llnl.gov/projects/sundials
[Differentiable Programming]: https://github.com/apple/swift/blob/main/docs/DifferentiableProgramming.md

[Swift Package Manager]: https://swift.org/package-manager/
[Swift API Design Guidelines]: https://swift.org/documentation/api-design-guidelines/

[Reference Documentation]: https://computing.llnl.gov/projects/sundials
[Semantic Versioning]: https://semver.org/

[Sundials.swift]: https://github.com/vojtamolda/Sundials.swift/
[Sundials.swift PRs]: https://github.com/vojtamolda/Sundials.swift/pulls
[Sundials.swift Issues]: https://github.com/vojtamolda/Sundials.swift/issues

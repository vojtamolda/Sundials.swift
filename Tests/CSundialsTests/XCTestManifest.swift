import Foundation
import XCTest
import CSundials


#if os(Linux)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(ARKODETests.allTests),
        testCase(CVODESTests.allTests),
        testCase(CVODETests.allTests),
        testCase(IDASTests.allTests),
        testCase(IDATests.allTests),
        testCase(KINSOLTests.allTests),
        testCase(NVectorTests.allTests),
        testCase(SUNLinSolTests.allTests),
        testCase(SUNMatrixTests.allTests)
    ]
}
#endif


/// Checks whether the difference between value and reference is within the specified tolerance.
///
/// Algorithm calculates the weighted root-mean-square (RMS) error of the difference between the
/// `reference` and the `value`. The weight vector of the comparison is defined as
/// `reltol * |reference| + abstol`.
///
/// - Parameters:
///   - value: Value to be checked.
///   - reference: The ground-truth, correct value to check against.
///   - reltol: Relative tolerance of the equality check.
///   - abstol: Absolute tolerance of the equality check.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you
///    call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call
///    this function.
func XCTAssertAlmostEqual(
    _ value: N_Vector?, _ reference: N_Vector?,
    _ reltol: Double, _ abstol: Double,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) {
    let absoluteTolerances = N_VClone(value)
    XCTAssertNotNil(absoluteTolerances)
    N_VConst(abstol, absoluteTolerances)
    
    XCTAssertAlmostEqual(value, reference, reltol,
                         absoluteTolerances!, message(),
                         file: file, line: line
    )
}

/// Checks whether the difference between value and reference is within the specified tolerance.
///
/// Algorithm calculates the weighted root-mean-square (RMS) error of the difference between the
/// `reference` and the `value`. The weight vector of the comparison is defined as
/// `reltol * |reference| + abstol`.
///
/// - Parameters:
///   - value: Value to be checked.
///   - reference: The ground-truth, correct value to check against.
///   - reltol: Relative tolerance of the equality check.
///   - abstol: Vector of absolute tolerances equality check for every component of value.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where you
///    call this function.
///   - line: The line number where the failure occurs. The default is the line number where you call
///    this function.
func XCTAssertAlmostEqual(
    _ value: N_Vector?, _ reference: N_Vector?,
    _ reltol: Double, _ abstol: N_Vector?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line)
{
    XCTAssertNotNil(value, message(), file: file, line: line)
    XCTAssertNotNil(reference, message(), file: file, line: line)
    XCTAssertNotNil(abstol, message(), file: file, line: line)
    XCTAssertEqual(N_VGetLength(value), N_VGetLength(reference),
                   file: file, line: line)
    XCTAssertGreaterThan(reltol, 0,
                         file: file, line: line)
    XCTAssertGreaterThan(N_VMin(abstol), 0,
                         file: file, line: line)

    let weights = N_VClone(value)
    defer { N_VDestroy(weights) }
    N_VAbs(reference, weights)
    N_VLinearSum(reltol, weights, +1, abstol, weights)
    N_VInv(weights, weights)

    let difference = N_VClone(reference)
    XCTAssertNotNil(difference)
    N_VLinearSum(+1, value, -1, reference, difference)
    let error = N_VWrmsNorm(difference, weights)
    XCTAssertLessThan(error, 1.0)
}

import XCTest


#if os(Linux)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(KINSOLTests.allTests),
        testCase(MatrixTests.allTests),
        testCase(VectorTests.allTests)
    ]
}
#endif

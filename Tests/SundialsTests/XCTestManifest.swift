import Foundation
import XCTest


#if os(Linux)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(MatrixTests.allTests),
        testCase(VectorTests.allTests)
    ]
}
#endif

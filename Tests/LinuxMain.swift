import XCTest
import CSundialsTests
import SundialsTests


var testsToRun = [XCTestCaseEntry]()
testsToRun += CSundialsTests.allTests()
testsToRun += SundialsTests.allTests()
XCTMain(testsToRun)

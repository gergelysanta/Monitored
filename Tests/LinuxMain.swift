import XCTest

import MonitoredTests

var tests = [XCTestCaseEntry]()
tests += MonitoredTests.allTests()
XCTMain(tests)

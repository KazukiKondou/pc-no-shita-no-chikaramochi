import XCTest

@testable import PCNoShitaNoChikaramochi

@MainActor
final class MemoryMonitorTests: XCTestCase {
    func testSamplePopulatesTotalBytes() {
        let monitor = MemoryMonitor()
        monitor.sample()
        XCTAssertGreaterThan(monitor.totalBytes, 0)
    }

    func testSampleProducesUsageInPercentRange() {
        let monitor = MemoryMonitor()
        monitor.sample()
        XCTAssertGreaterThanOrEqual(monitor.usage, 0)
        XCTAssertLessThanOrEqual(monitor.usage, 100)
    }

    func testUsedBytesDoNotExceedTotal() {
        let monitor = MemoryMonitor()
        monitor.sample()
        XCTAssertLessThanOrEqual(monitor.usedBytes, monitor.totalBytes)
    }

    func testStopIsSafeWithoutStart() {
        let monitor = MemoryMonitor()
        monitor.stop()  // クラッシュしないこと
    }
}

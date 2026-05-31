import Darwin
import Foundation

@MainActor
final class MemoryMonitor: ObservableObject {
    @Published private(set) var usage: Double = 0.0
    @Published private(set) var usedBytes: UInt64 = 0
    @Published private(set) var totalBytes: UInt64 = 0

    private var timer: Timer?

    func start(interval: TimeInterval = 1.0) {
        sample()
        // .common モードで登録することで、メニュー表示中 (eventTracking) でも Timer が止まらない
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// 現在のメモリ状況を 1 回サンプリングする。テストから直接呼べるよう internal。
    func sample() {
        if totalBytes == 0 {
            totalBytes = ProcessInfo.processInfo.physicalMemory
        }

        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, ptr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed

        usedBytes = used
        guard totalBytes > 0 else { return }
        usage = max(0, min(100, Double(used) / Double(totalBytes) * 100))
    }
}

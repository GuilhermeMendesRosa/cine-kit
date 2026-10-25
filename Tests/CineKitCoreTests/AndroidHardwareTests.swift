import Testing
@testable import CineKitCore

struct AndroidHardwareTests {
    @Test func coreOptionsStopAtTheHostCores() {
        #expect(AndroidRuntime.Hardware.coreOptions(hostCores: 4) == [2, 4])
        #expect(AndroidRuntime.Hardware.coreOptions(hostCores: 10) == [2, 4, 6, 8])
    }

    @Test func memoryOptionsStopAtHalfThePhysicalMemory() {
        #expect(AndroidRuntime.Hardware.memoryOptions(physicalMemory: 8 << 30) == [2048, 4096])
        #expect(AndroidRuntime.Hardware.memoryOptions(physicalMemory: 16 << 30) == [2048, 4096, 8192])
    }

    @Test func savedValueOutsideTheOptionsFallsBackToTheDefault() {
        let tooManyCores = AndroidRuntime.Hardware(resolution: .hd1080, cores: 8, memoryMB: 2048, hostCores: 4, physicalMemory: 16 << 30)
        let unset = AndroidRuntime.Hardware(resolution: .hd1080, cores: 4, memoryMB: 0, hostCores: 10, physicalMemory: 16 << 30)
        let tooMuchMemory = AndroidRuntime.Hardware(resolution: .hd1080, cores: 4, memoryMB: 8192, hostCores: 10, physicalMemory: 8 << 30)

        #expect(tooManyCores.cores == 4)
        #expect(unset.memoryMB == 2048)
        #expect(tooMuchMemory.memoryMB == 2048)
    }
}

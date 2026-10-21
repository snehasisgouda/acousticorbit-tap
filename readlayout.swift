// readlayout.swift — what the HAL SERVES as a device's preferred channel
// layout, per scope (the figure Apple Music reads to decide what to
// render). Plain CoreAudio, no app code, so it answers independently of
// the engine. Build and run:
//   swiftc -O readlayout.swift -o /tmp/readlayout && /tmp/readlayout "Acoustic Orbit"
// (driver version 3 and older: "Speaker LCR"; the argument is a substring,
// so the default also lists the "Acoustic Orbit Array" aggregate while the
// array plays — each line names its device)
// 20 Oct 2026: this is the instrument that showed driver version 2's
// tag-only Atmos answer being served as an EMPTY table (descs 0) while
// the written 16-label table sat unused in the system plist, and
// version 3's description table being served whole (descs 16).
import CoreAudio
import Foundation

func devices() -> [AudioDeviceID] {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr else { return [] }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr else { return [] }
    return ids
}
func name(_ id: AudioDeviceID) -> String {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var cf: Unmanaged<CFString>? = nil
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &cf) == noErr, let s = cf?.takeRetainedValue() else { return "?" }
    return s as String
}
func layout(_ id: AudioDeviceID, _ scope: AudioObjectPropertyScope) -> String {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyPreferredChannelLayout, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    guard AudioObjectHasProperty(id, &addr) else { return "no property" }
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr else { return "size error" }
    let bytes = max(Int(size), MemoryLayout<AudioChannelLayout>.size)
    let raw = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: 8); defer { raw.deallocate() }
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
    let st = AudioObjectGetPropertyData(id, &addr, 0, nil, &size, raw)
    guard st == noErr else { return "read error \(st)" }
    let l = raw.assumingMemoryBound(to: AudioChannelLayout.self)
    let tag = l.pointee.mChannelLayoutTag, n = Int(l.pointee.mNumberChannelDescriptions)
    let off = MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)!
    let room = (Int(size) - off) / MemoryLayout<AudioChannelDescription>.stride
    let count = max(0, min(n, room))
    var labels: [UInt32] = []
    if count > 0 { let d = (raw + off).bindMemory(to: AudioChannelDescription.self, capacity: count); labels = (0..<count).map { d[$0].mChannelLabel } }
    return String(format: "size %d tag 0x%08X (%u) descs %d labels %@", Int(size), tag, tag, n, labels.description)
}
let want = CommandLine.arguments.dropFirst().first ?? "Acoustic Orbit"
for id in devices() where name(id).contains(want) {
    print("\(name(id)) [\(id)]")
    print("  output:", layout(id, kAudioObjectPropertyScopeOutput))
    print("  input: ", layout(id, kAudioObjectPropertyScopeInput))
}

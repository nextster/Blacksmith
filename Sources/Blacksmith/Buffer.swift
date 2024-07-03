import Foundation
import Metal

public protocol BSBuffer {
    var mtlBuffer: MTLBuffer { get }
}

public struct BSDynamicBuffer<T> {
    static var alignedSize: Int {
        MemoryLayout<T>.stride
    }
    public let mtlBuffer: MTLBuffer
//    public let alignedSize: Int
//    public let size: Int
    public let buffersCount: Int
    private var index: Int = 0
    public var offset: Int = 0
    
    public init(buffersCount: Int, storageMode: MTLResourceOptions = [], label: String = "", device: BSDevice) {
        self.buffersCount = buffersCount
//        var value = value
        self.mtlBuffer = device.buffer(
            length: BSDynamicBuffer<T>.alignedSize * buffersCount,
            storageMode: .storageModeShared
        )
        self.mtlBuffer.label = label
    }
    
    public var currentBufferValue: T {
        return bufferValueFor(offset: offset).pointee
    }
    
    public func withCurrentValue(_ handler: (_ pointer: inout T) -> Void) {
        handler(&bufferValueFor(offset: offset).pointee)
    }
    
    public func withAllValues(_ handler: (_ pointer: inout T) -> Void) {
        for idx in 0..<buffersCount {
            let offset = offsetFor(idx: idx)
            handler(&bufferValueFor(offset: offset).pointee)
        }
    }
    
    public mutating func nextBuffer() {
        index = (index + 1) % buffersCount
        offset = offsetFor(idx: index)
    }
    
    @inline(__always)
    private func bufferValueFor(offset: Int) -> UnsafeMutablePointer<T> {
        UnsafeMutableRawPointer(mtlBuffer.contents() + offset).bindMemory(to: T.self, capacity: 1)
    }
    
    @inline(__always)
    private func offsetFor(idx: Int) -> Int {
        BSDynamicBuffer<T>.alignedSize * idx
    }
}

public struct BSScalarBuffer<T> {
    public let mtlBuffer: MTLBuffer
    
    
    public init(storageMode: MTLResourceOptions = [], device: BSDevice) {
        self.mtlBuffer = device.buffer(length: MemoryLayout<T>.size * 2, storageMode: storageMode)
    }
    
    public var bufferValue: T {
        return mtlBuffer.contents().bindMemory(to: T.self, capacity: 1).pointee
    }
    
    public func withValue(_ handler: (_ pointer: inout T) -> Void) {
        handler(&mtlBuffer.contents().bindMemory(to: T.self, capacity: 1).pointee)
    }
}

public struct BSVectorBuffer<T> {
    public let mtlBuffer: MTLBuffer
    public let count: Int
    
    public init(_ value: Array<T>, storageMode: MTLResourceOptions = [], device: BSDevice) {
        self.count = value.count
        self.mtlBuffer = device.buffer(array: value, storageMode: storageMode)
    }
    
    public var bufferValue: UnsafeMutableBufferPointer<T> {
        let ptr = mtlBuffer.contents().bindMemory(to: T.self, capacity: count)
        return UnsafeMutableBufferPointer(start: ptr, count: count)
    }
    
    public func withValue(_ handler: (_ pointer: UnsafeMutableBufferPointer<T>) -> Void) {
        handler(bufferValue)
    }
}

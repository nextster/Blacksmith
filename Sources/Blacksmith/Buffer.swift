import Foundation
import Metal

public protocol BSBuffer {
    var mtlBuffer: MTLBuffer { get }
}

public struct BSDynamicBuffer<T> {
    static var alignedSize: Int {
        (MemoryLayout<T>.size + 0xFF) & -0x100
    }
    public let mtlBuffer: MTLBuffer
//    public let alignedSize: Int
//    public let size: Int
    public let buffersCount: Int
    private var index: Int = 0
    public var offset: Int = 0
    
    public init(buffersCount: Int, storageMode: MTLResourceOptions = [], label: String = "") {
        self.buffersCount = buffersCount
//        var value = value
        self.mtlBuffer = MetalDevice.sharedInstance.buffer(length: BSDynamicBuffer<T>.alignedSize * buffersCount, storageMode: .storageModeShared)
        self.mtlBuffer.label = label
    }
    
    public var bufferValue: UnsafeMutablePointer<T> {
        return UnsafeMutableRawPointer(mtlBuffer.contents() + offset).bindMemory(to: T.self, capacity: 1)
    }
    
    public func withValue(_ handler: (_ pointer: inout T) -> Void) {
        handler(&bufferValue.pointee)
    }
    
    public mutating func nextBuffer() {
        index = (index + 1) % buffersCount
        offset = BSDynamicBuffer<T>.alignedSize * index
    }
}

public struct BSScalarBuffer<T> {
    public let mtlBuffer: MTLBuffer
    
    public init(_ value: T, storageMode: MTLResourceOptions = []) {
        var value = value
        self.mtlBuffer = MetalDevice.sharedInstance.buffer(element: &value, storageMode: storageMode)
    }
    
    public var bufferValue: UnsafeMutablePointer<T> {
        return mtlBuffer.contents().bindMemory(to: T.self, capacity: 1)
    }
    
    public func withValue(_ handler: (_ pointer: inout T) -> Void) {
        handler(&bufferValue.pointee)
    }
}

public struct BSVectorBuffer<T> {
    public let mtlBuffer: MTLBuffer
    public let count: Int
    
    public init(_ value: Array<T>, storageMode: MTLResourceOptions = []) {
        self.count = value.count
        self.mtlBuffer = MetalDevice.sharedInstance.buffer(array: value, storageMode: storageMode)
    }
    
    public var bufferValue: UnsafeMutableBufferPointer<T> {
        let ptr = mtlBuffer.contents().bindMemory(to: T.self, capacity: count)
        return UnsafeMutableBufferPointer(start: ptr, count: count)
    }
    
    public func withValue(_ handler: (_ pointer: UnsafeMutableBufferPointer<T>) -> Void) {
        handler(bufferValue)
    }
}

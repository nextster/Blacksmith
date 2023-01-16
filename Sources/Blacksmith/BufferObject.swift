import Foundation
import Metal

public struct ScalarBufferObject<T> {
    var value: T
    public let buffer: MTLBuffer
    
    public init(_ value: T, storageMode: MTLResourceOptions = []) {
        self.value = value
        self.buffer = MetalDevice.sharedInstance.buffer(element: &self.value, storageMode: storageMode)
    }
    
    public var bufferValue: UnsafeMutablePointer<T> {
        return buffer.contents().bindMemory(to: T.self, capacity: 1)
    }
    
    public func withValue(_ handler: (_ pointer: inout T) -> Void) {
        handler(&bufferValue.pointee)
    }
}

public struct VectorBufferObject<T> {
    var value: Array<T>
    public let buffer: MTLBuffer
    public let count: Int
    
    public init(_ value: Array<T>, storageMode: MTLResourceOptions = []) {
        self.value = value
        self.count = value.count
        self.buffer = MetalDevice.sharedInstance.buffer(array: self.value, storageMode: storageMode)
    }
    
    public var bufferValue: UnsafeMutableBufferPointer<T> {
        let ptr = buffer.contents().bindMemory(to: T.self, capacity: count)
        return UnsafeMutableBufferPointer(start: ptr, count: count)
    }
    
    public func withValue(_ handler: (_ pointer: UnsafeMutableBufferPointer<T>) -> Void) {
        handler(bufferValue)
    }
}

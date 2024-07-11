import Foundation
import Metal
import MetalKit

public class BSDevice {
    enum Errors: Error {
        case failedToCreateFunction(name: String)
        case cannotCreateDepthState
    }
    
    private let pipelineCache = NSCache<AnyObject, AnyObject>()
    
    public let mtlDevice: MTLDevice
    let commandQueue: MTLCommandQueue
    
    private lazy var textureLoader: MTKTextureLoader = {
        MTKTextureLoader(device: mtlDevice)
    }()
    
    let defaultLibrary: MTLLibrary
    
    public init(mtlDevice: MTLDevice) {
        self.mtlDevice = mtlDevice
        commandQueue = mtlDevice.makeCommandQueue()!
        defaultLibrary = mtlDevice.makeDefaultLibrary()!
    }
    
    // MARK: Convenient methods
    public final func createTexture(descriptor: MTLTextureDescriptor) -> MTLTexture {
        return self.mtlDevice.makeTexture(descriptor: descriptor)!
    }
    
    final func buffer(length: Int, storageMode: MTLResourceOptions = []) -> MTLBuffer {
        return mtlDevice.makeBuffer(length: length, options: storageMode)!
    }
    
    final func buffer<T>(element: inout T, storageMode: MTLResourceOptions = []) -> MTLBuffer {
        let size = MemoryLayout<T>.stride
        return mtlDevice.makeBuffer(bytes: &element, length: size, options: storageMode)!
    }
    
    final func buffer<T>(array: Array<T>, storageMode: MTLResourceOptions = []) -> MTLBuffer {
        let size = array.count * MemoryLayout<T>.stride
        return mtlDevice.makeBuffer(bytes: array, length: size, options: storageMode)!
    }
    
    public final func newCommandBuffer() -> MTLCommandBuffer? {
        commandQueue.makeCommandBuffer()
    }
}

extension BSDevice {
    public final func createRenderPipeline(
        vertex: String,
        fragment: String,
        _ configure: (MTLRenderPipelineDescriptor) -> Void
    ) throws -> MTLRenderPipelineState {
        let cacheKey = NSString(string: vertex + fragment)
        
        if let pipelineState = pipelineCache.object(forKey: cacheKey) as? MTLRenderPipelineState {
            return pipelineState
        }
        
        guard let vertexFunction = defaultLibrary.makeFunction(name: vertex) else {
            throw Errors.failedToCreateFunction(name: vertex)
        }
        
        guard let fragmentFunction = defaultLibrary.makeFunction(name: fragment) else {
            throw Errors.failedToCreateFunction(name: fragment)
        }
        
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFunction
        desc.fragmentFunction = fragmentFunction
        
        configure(desc)
        
        let pipelineState = try mtlDevice.makeRenderPipelineState(descriptor: desc)
        
        pipelineCache.setObject(pipelineState, forKey: cacheKey)
        
        return pipelineState
    }
    
    public final func createComputePipeline(computeFunctionName: String) throws -> MTLComputePipelineState {
        let cacheKey = NSString(string: computeFunctionName)
        
        if let pipelineState = pipelineCache.object(forKey: cacheKey) as? MTLComputePipelineState {
            return pipelineState
        }
        
        guard let computeFunction = defaultLibrary.makeFunction(name: computeFunctionName) else {
            throw Errors.failedToCreateFunction(name: computeFunctionName)
        }
        
        let pipelineState =  try mtlDevice.makeComputePipelineState(function: computeFunction)
        
        pipelineCache.setObject(pipelineState, forKey: cacheKey)
        
        return pipelineState
    }
    
    public func loadTexture(name: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        
        let textureLoaderOptions: [MTKTextureLoader.Option : Any] = [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: name,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
        
    }
    
    public final func loadTexture(url: URL) throws -> MTLTexture {
        return try textureLoader.newTexture(URL: url)
    }
}
extension BSDevice {
    func makeDepthStencilState(view: MTKView) throws -> MTLDepthStencilState {
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDescriptor.isDepthWriteEnabled = true
        guard let depthState = mtlDevice.makeDepthStencilState(descriptor: depthStateDescriptor) else {
            throw Errors.cannotCreateDepthState
        }
        return depthState
    }
}

import MetalKit

open class BSRenderer<U>: NSObject, MTKViewDelegate {
    public enum Errors: String, Error {
        case badVertexDescriptor
        case deviceNotFoundInView
    }
    open class var maxBuffersInFlight: Int { 3 }
    
    public let view: MTKView
    public let device: BSDevice
    
    public var uniformBuffer: BSDynamicBuffer<U>!
    public var depthState: MTLDepthStencilState
    
    let inFlightSemaphore = DispatchSemaphore(value: BSRenderer.maxBuffersInFlight)
    
    public init(view: MTKView) throws {
        self.view = view
        guard let mtlDevice = view.device else {
            throw Errors.deviceNotFoundInView
        }
        let device = BSDevice(mtlDevice: mtlDevice)
        self.device = device
        
        uniformBuffer = BSDynamicBuffer<U>(
            buffersCount: BSRenderer.maxBuffersInFlight,
            label: "UniformBuffer",
            device: device
        )
        
        depthState = try device.makeDepthStencilState(view: view)
        
        super.init()
    }
    
    open func draw(in view: MTKView) {
        /// Per frame updates hare
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        guard let commandBuffer = device.newCommandBuffer() else { return }
        
        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }
        
        defer { commandBuffer.commit() }
        uniformBuffer.nextBuffer()
        
        /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
        ///   holding onto the drawable and blocking the display pipeline any longer than necessary
        let renderPassDescriptor = view.currentRenderPassDescriptor
        
        guard let renderPassDescriptor = renderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        //
        renderEncoder.label = "Primary Render Encoder"
        render(renderEncoder)
        
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
    }
    
    open func render(_ encoder: MTLRenderCommandEncoder) {}
    open func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

extension BSRenderer {
    public func createRenderShader(
        view: MTKView,
        fragmentShader: String,
        vertexShader: String,
        pixelFormat: MTLPixelFormat? = nil
    ) throws -> BSRenderShader {
        
        throw Errors.deviceNotFoundInView
    }
}

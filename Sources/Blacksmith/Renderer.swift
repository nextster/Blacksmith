import MetalKit

open class BSRenderer<U>: NSObject, MTKViewDelegate {
    public enum Errors: Error {
        case badVertexDescriptor
    }
    open class var maxBuffersInFlight: Int { 3 }
    
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    
    public var uniformBuffer: BSDynamicBuffer<U>!
    public var depthState: MTLDepthStencilState
    
    let inFlightSemaphore = DispatchSemaphore(value: BSRenderer.maxBuffersInFlight)
    
    public init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        uniformBuffer = BSDynamicBuffer<U>(buffersCount: BSRenderer.maxBuffersInFlight,
                                           label: "UniformBuffer")
        
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDescriptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor: depthStateDescriptor) else { return nil }
        depthState = state
        
        super.init()
    }
    
    open func draw(in view: MTKView) {
        /// Per frame updates hare
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { _ in
                semaphore.signal()
            }
            
            uniformBuffer.nextBuffer()
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
//                        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 0.5)
//
                renderEncoder.label = "Primary Render Encoder"
                render(renderEncoder)
                
                renderEncoder.endEncoding()
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            
            commandBuffer.commit()
        }
    }
    
    open func render(_ encoder: MTLRenderCommandEncoder) {}
    
    open func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

import MetalKit

open class MTLRenderer: NSObject {
    public let device = MetalDevice.sharedInstance
}

extension MTLRenderer: MTKViewDelegate {
    open func draw(in view: MTKView) {
    }
    
    open func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.device = device.mtlDevice
    }
}

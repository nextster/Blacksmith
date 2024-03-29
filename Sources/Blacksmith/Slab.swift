import MetalKit

public class BSSlab {
    public var ping: MTLTexture
    public var pong: MTLTexture
    
    public init(size: float2, format: MTLPixelFormat = .rg16Float, name: String, device: BSDevice) {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = format
        textureDescriptor.usage = [.shaderRead, .renderTarget]
        textureDescriptor.width = Int(size.x)
        textureDescriptor.height = Int(size.y)

        ping = device.createTexture(descriptor: textureDescriptor)
        pong = device.createTexture(descriptor: textureDescriptor)
        
        ping.label = name
        pong.label = name
    }
    
    public func swap() {
        let temp = ping
        ping = pong
        pong = temp
    }
}

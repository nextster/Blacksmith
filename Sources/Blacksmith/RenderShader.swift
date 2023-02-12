import Foundation
import CoreMedia
import Metal

public class BSRenderShader {
    private var name: String
    private var renderPipelineState: MTLRenderPipelineState
    private var textureSet: BSSlab?
    private let vertexBuffer: MTLBuffer
    private let fragmentBuffer: MTLBuffer
    private let indicesBuffer: BSVectorBuffer<UInt16>
    
    public init(
        vertexShader: String,
        fragmentShader: String,
        pixelFormat: MTLPixelFormat = .rg16Float,
        vertexBuffer: MTLBuffer,
        fragmentBuffer: MTLBuffer,
        indicesBuffer: BSVectorBuffer<UInt16>,
        textureSet: BSSlab? = nil
    ) {
        name = fragmentShader
        
        self.textureSet = textureSet
        self.vertexBuffer = vertexBuffer
        self.fragmentBuffer = fragmentBuffer
        self.indicesBuffer = indicesBuffer
        
        renderPipelineState = try! MetalDevice.createRenderPipeline(
            vertexFunctionName: vertexShader,
            fragmentFunctionName: fragmentShader,
            pixelFormat: pixelFormat
        )
    }
    
    deinit {
        print("Deinit Filter")
    }
    
    public final func execute(commandBuffer: MTLCommandBuffer,
                              textureSet: BSSlab,
                              fragmentTextures: [MTLTexture]) {
        execute(commandBuffer: commandBuffer,
                texture: textureSet.pong,
                fragmentTextures: fragmentTextures)
        textureSet.swap()
    }
    
    public final func execute(commandBuffer: MTLCommandBuffer,
                              texture: MTLTexture,
                              fragmentTextures: [MTLTexture]) {
        let renderPassDescriptor = configureRenderPassDescriptor(texture: texture)
        if let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            
            renderCommandEncoder.pushDebugGroup("Render Encoder \(name)")
            
            renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            for (idx, txt) in fragmentTextures.enumerated() {
                renderCommandEncoder.setFragmentTexture(txt, index: idx)
            }
            
            renderCommandEncoder.setFragmentBuffer(fragmentBuffer, offset: 0, index: 0)
            
            renderCommandEncoder.setCullMode(.back)
            renderCommandEncoder.setRenderPipelineState(renderPipelineState)
            
            renderCommandEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indicesBuffer.count,
                indexType: .uint16,
                indexBuffer: indicesBuffer.mtlBuffer,
                indexBufferOffset: 0
            )
            
            renderCommandEncoder.endEncoding()
            
            renderCommandEncoder.popDebugGroup()
        }
    }
    
    private func configureRenderPassDescriptor(texture: MTLTexture?) -> MTLRenderPassDescriptor {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(
            0.0, 0.0, 0.0, 1.0
        )
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        return renderPassDescriptor
    }
}





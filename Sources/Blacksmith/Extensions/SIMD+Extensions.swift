import Foundation
import CoreGraphics

public typealias float1 = Float
public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

public extension CGPoint {
    var simd: float2 {
        .init(x: Float(x), y: Float(y))
    }
}

public extension CGRect {
    var simd: float4 {
        .init(x: Float(origin.x), y: Float(origin.y), z: Float(size.width), w: Float(size.height))
    }
}

public extension CGSize {
    var simd: float2 {
        .init(x: Float(width), y: Float(height))
    }
}

public extension CGFloat {
    var simd: float1 {
        Float(self)
    }
}

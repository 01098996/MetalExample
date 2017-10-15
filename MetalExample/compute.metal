//
//  compute.metal
//  MetalExample
//
//  Created by ZhangXiaoJun on 2017/10/15.
//  Copyright © 2017年 XiaoJunZhang. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant float3 kGrayScale = float3(0.2989,0.5870,0.1140);

kernel void grayKernel(texture2d<float, access::read> inputImageTexture [[texture(0)]],
                       texture2d<float, access::write> outputImageTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inputImageTexture.read(gid);
    float gray = dot(kGrayScale,inColor.rgb);
    outputImageTexture.write(float4(gray,gray,gray,inColor.a), gid);
}

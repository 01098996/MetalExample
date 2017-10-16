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
                       device uchar4 *outputResult [[ buffer(0) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inputImageTexture.read(gid);
    float gray = dot(kGrayScale,inColor.rgb);
    
    uint width = inputImageTexture.get_width();
    uint height = inputImageTexture.get_height();
    uint index = min(gid.x, width) + min(gid.y, height) * width;
    float4 result = float4(float3(gray),inColor.a);
    outputResult[index] = uchar4(uchar3(gray * 255), inColor.a * 255);
    outputImageTexture.write(result, gid);
}

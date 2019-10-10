//
//  MAVShader.metal
//  MagicAV
//
//  Created by 姜世祺 on 2019/9/12.
//  Copyright © 2019 Joyoki. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    
    float2 textureCoordinate; // 纹理坐标，会做插值处理
    
} MAVRasterizerData;

vertex MAVRasterizerData // 返回给片元着色器的结构体
vertexShader(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
             constant float4 *pPosition [[ buffer(0) ]],
             constant float2 *pTexCoords [[ buffer(1) ]]) { // buffer表明是缓存数据，0是索引
    MAVRasterizerData out;
    out.clipSpacePosition = pPosition[vertexID];
    out.textureCoordinate = pTexCoords[vertexID];
    return out;
}

fragment half4
samplingShader(MAVRasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<half> inputTexture [[ texture(0) ]],
               sampler         samplr        [[ sampler(0) ]])
{
    return inputTexture.sample(samplr, input.textureCoordinate);
}

constant half SquareSize = 0.125 - 1.0/512.0;
constant half StepSize = 0.5/512.0;

// Compute kernel
kernel void rosyEffect(texture2d<half, access::read> lutTexture  [[ texture(0) ]],
                       texture2d<half, access::read> inputTexture [[ texture(1) ]],
                       texture2d<half, access::write> outputTexture [[ texture(2) ]],
                       device float *intensity [[ buffer(0) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    half4 inputColor = inputTexture.read(gid);
    
    float blueColor = inputColor.b * 63.0;
    
    int2 quad1;
    quad1.y = floor(floor(blueColor) * 0.125);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);

    int2 quad2;
    quad2.y = floor(ceil(blueColor) * 0.125);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);

    half2 texPos1;
    texPos1.x = (quad1.x * 0.125) + StepSize + (SquareSize * inputColor.r);
    texPos1.y = (quad1.y * 0.125) + StepSize + (SquareSize * inputColor.g);
    
    half2 texPos2;
    texPos2.x = (quad2.x * 0.125) + StepSize + (SquareSize * inputColor.r);
    texPos2.y = (quad2.y * 0.125) + StepSize + (SquareSize * inputColor.g);

    half4 lutColor1 = lutTexture.read(uint2(texPos1.x * 512, texPos1.y * 512));
    half4 lutColor2 = lutTexture.read(uint2(texPos2.x * 512, texPos2.y * 512));
    
    half4 lutColor = mix(lutColor1, lutColor2, fract(blueColor));
    half4 newColor = mix(inputColor, half4(lutColor.rgb,inputColor.a), *intensity);
    outputTexture.write(newColor, gid);
}

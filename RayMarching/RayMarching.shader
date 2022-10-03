Shader "PostProcess/RayMarching"
{
    SubShader
    {
        Cull Off Zwrite Off Ztest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertDefault
            #pragma fragment frag

            // #include "Packages/com.unity.postprocessing/PostProssing/Shaders/StdLib.hlsl"
            #include "Library/PackageCache/com.unity.postprocessing@2.3.0/PostProcessing/Shaders/StdLib.hlsl"

            TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
            TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
            float4x4 _InverseProjectorMatrix;
            float4x4 _InverseViewMatrix;
            float _Step;
            float3 _boundMin;
            float3 _boundMax;
            sampler3D _shapeTex;

            float4 GetWorldSpacePosition(float2 uv, float depth)
            {
                // 投影 转 观察
                float4 viewPos = mul(_InverseProjectorMatrix, float4(uv*2-1,depth,1));
                viewPos.xyz /= viewPos.w;
                // 观察 转 世界
                float4 worldPos= mul(_InverseViewMatrix,float4(viewPos.xyz,1));
                return worldPos;
            }

            float2 RayBoxDst(float3 boundMin, float3 boundMax, float3 origin, float3 dir)
            {
                float3 dir_rev = 1 / dir;
                float3 t0 = (boundMin - origin) * dir_rev;
                float3 t1 = (boundMax - origin) * dir_rev;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(min(tmax.x, tmax.y), tmax.z);

                float dstBound = max(0, dstA);
                float dstInsideInBox = max(0, dstB - dstBound);

                return float2(dstBound, dstInsideInBox);
            }

            float SampleDensity(float3 p)
            {
                float3 boxCenter = (_boundMax + _boundMin) * 0.5;
                float3 boxSize = _boundMax - _boundMin;
                float3 pp = (p - boxCenter) / boxSize;
                float3 uvw = (pp + 1) * 0.5;
                float4 col = tex3D(_shapeTex, uvw);
                float density = col.r * (0.625 * col.g + 0.25 * col.b + 0.125 * col.a);
                return density;
            }
            
            float RayMarching(float3 enter, float dir, float dstLimit)
            {
                float sum = 0;
                // float step = 1;
                float step = _Step;
                float curStep = 0;
                float3 curPoint = enter;
                float3 stepDir = dir * step;
                // 在循环中对贴图进行采样时，需要在循环上面打上 unroll 标签，这样在编译时会对循环进行展开，否则会有警告
                [unroll(32)]
                for(int i = 0; i < 32; i++)
                {
                    if(curStep < dstLimit)
                    {
                        curStep += step;
                        curPoint += stepDir;
                        float density = SampleDensity(curPoint);
                        sum += pow(density, 2.5);// 密度整体变得更小，边缘会明显一些，更像烟雾
                        if(sum > 1) break;
                    }
                    else break;
                }
                return sum;
            }

            
            
            float4 frag (VaryingsDefault i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,i.texcoordStereo);
                float3 worldPos = GetWorldSpacePosition(i.texcoord, depth).xyz;
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 ray = worldPos - rayOrigin;
                float3 dir = normalize(ray);

                float2 boxDst = RayBoxDst(_boundMin, _boundMax, rayOrigin, dir);
                float dstBound = boxDst.x;
                float dstInside = boxDst.y;
                float depthLinear = length(ray);
                float dstLimit = min(depthLinear - dstBound, dstInside);

                float marched = RayMarching(rayOrigin+dir*dstBound, dir, dstLimit);
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                return col + marched;
            }
            ENDHLSL
        }
    }
}

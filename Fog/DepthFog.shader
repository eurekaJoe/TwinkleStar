// jave.lin 2020.04.17 - 深度雾 - 代码写法很多可以优化，这里做学习用，便于高可读性
Shader "Custom/DepthFog" {
    Properties {
        [KeywordEnum(VIEWSPACE,WORLDSPACE)] _DIST_TYPE ("Distance type", int) = 0
        [KeywordEnum(LINEAR,EXP,EXP2)] _FUNC_TYPE ("Calculate Func type", int) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}  // 噪点

        _FogColor ("Fog Color", Color) = (0.5, 0.5, 0.5, 1)

        _Start ("Start", Float) = 0
        _End ("End", Float) = 100

        _Density ("Density", Range(0, 1)) = 0.3
    }
    SubShader {
        ZWrite Off ZTest Always Cull Off
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _DIST_TYPE_VIEWSPACE _DIST_TYPE_WORLDSPACE
            #pragma multi_compile _FUNC_TYPE_LINEAR _FUNC_TYPE_EXP _FUNC_TYPE_EXP2
            #include "UnityCG.cginc"
            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint id : SV_VertexID;
            };
            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };
            sampler2D _CameraDepthTexture;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _FogColor;
            float4x4 _Ray;
            float _Start;
            float _End;
            float _Density;
            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ray = _Ray[v.id].xyz;
                return o;
            }
            fixed4 frag (v2f i) : SV_Target {

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                // return depth;

                // 下面的dist就是我们博客文章中公式的z
                float dist = 0;
                // dist：depth to world pos
                #if _DIST_TYPE_VIEWSPACE
                // 以view space .z
                float eyeZ = LinearEyeDepth(depth);
                dist = eyeZ;
                
                #else // _DIST_TYPE_WORLDSPACE
                // dist：以world space distance
                float linear01depth = Linear01Depth(depth);
                // float3 wp = _WorldSpaceCameraPos.xyz + i.ray * linear01depth;
                dist = length(i.ray * linear01depth);

                #endif

                float factor = 0;
                #if _FUNC_TYPE_LINEAR
                // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
                factor = (_End - dist) / (_End - _Start);
                
                #elif _FUNC_TYPE_EXP
                // factor = exp(-density*z)
                factor = exp(-(_Density * dist));

                #else // _FUNC_TYPE_EXP
                // factor = exp(-(density*z)^2)
                factor = exp(-pow(_Density * dist, 2));

                #endif

                factor = saturate(factor);

                return lerp(_FogColor, tex2D(_MainTex, i.uv), factor);
            }
            ENDCG
        }
    }
}


Shader "Custom/Star"
{
	Properties
	{
		_Color("Color",color) =(1,1,1,1)
		[HDR]_StarColor("StarColor",color) = (1,1,1,1)

		_MainTex ("Texture", 2D) = "white" {}
		_StarTex("StarTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 viewDir:TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _StarTex;
			float4 _StarTex_ST;
			float4 _Color;
			float4 _StarColor;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// 采样Albedo
				fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex))*_Color;
			    //第一次采样星光图，
			    fixed4 star01 = tex2D(_StarTex, TRANSFORM_TEX(i.uv, _StarTex));
			   //第二次采样星光贴图，并且加上视线方向，保证视角在转动的时候，第二次采样的UV做偏移
			   fixed4 star02 = tex2D(_StarTex, TRANSFORM_TEX(i.uv , _StarTex) + i.viewDir/5);
			   //把两张星光图简单相乘，只有两张图有白点重合的地方才会显示，这样就有闪烁的效果了，最后乘上星光颜色
			   col.rgb += (star01.rgb*star02.rgb*_StarColor);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}

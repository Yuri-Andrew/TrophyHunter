//
// https://github.com/SlightlyMad/AtmosphericScattering
//  Copyright(c) 2016, Michal Skalsky
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors
//     may be used to endorse or promote products derived from this software without
//     specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
//  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



Shader "WeatherMaker/WeatherMakerAtmosphericScatteringLookupShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ZTest ("ZTest", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		CGINCLUDE

		#define WEATHER_MAKER_ENABLE_TEXTURE_DEFINES

		#include "WeatherMakerAtmosphereShaderInclude.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
		};
		
		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 wpos : TEXCOORD1;
		};
		               
		ENDCG
            
		// pass 0 - precompute particle density
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

			CGPROGRAM

            #pragma vertex vertQuad
            #pragma fragment particleDensityLUT
            #pragma target 3.5

            #define UNITY_HDR_ON

            struct v2p
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            struct input
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            v2p vertQuad(input v)
            {
                v2p o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                return o;
            }

			float2 particleDensityLUT(v2p i) : SV_Target
			{
                float cosAngle = i.uv.x * 2.0 - 1.0;
                float sinAngle = sqrt(saturate(1 - cosAngle * cosAngle));
                float startHeight = lerp(0.0, _WeatherMakerAtmosphereHeight, i.uv.y);

                float3 rayStart = float3(0, startHeight, 0);
                float3 rayDir = float3(sinAngle, cosAngle, 0);
                
				return PrecomputeParticleDensity(rayStart, rayDir);
			}

			ENDCG
		}
			
		// pass 1 - ambient light LUT
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

			CGPROGRAM

			#pragma vertex vertQuad
			#pragma fragment fragDir
			#pragma target 3.5

			struct v2p
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct input
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2p vertQuad(input v)
			{
				v2p o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				return o;
			}

			float4 fragDir(v2f i) : SV_Target
			{
				float cosAngle = i.uv.x * 1.1 - 0.1;// *2.0 - 1.0;
                float sinAngle = sqrt(saturate(1 - cosAngle * cosAngle));
                float3 lightDir = -normalize(float3(sinAngle, cosAngle, 0));
				return fixed4(PrecomputeAmbientLight(lightDir), 1.0);
			}
			ENDCG
		}

		// pass 2 - dir light LUT
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

			CGPROGRAM

			#pragma vertex vertQuad
			#pragma fragment fragDir
			#pragma target 3.5

			struct v2p
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct input
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2p vertQuad(input v)
			{
				v2p o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				return o;
			}

			float4 fragDir(v2f i) : SV_Target
			{
				float cosAngle = i.uv.x * 1.1 - 0.1;// *2.0 - 1.0;
				float sinAngle = sqrt(saturate(1 - cosAngle * cosAngle));				
				float3 rayDir = normalize(float3(sinAngle, cosAngle, 0));
				return PrecomputeDirLight(rayDir);
			}
			ENDCG
		}
	}
}

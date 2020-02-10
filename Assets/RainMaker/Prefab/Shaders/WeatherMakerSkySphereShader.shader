//
// Weather Maker for Unity
// (c) 2016 Digital Ruby, LLC
// Source code may be used for personal or commercial projects.
// Source code may NOT be redistributed or sold.
// 
// *** A NOTE ABOUT PIRACY ***
// 
// If you got this asset from a pirate site, please consider buying it from the Unity asset store at https://www.assetstore.unity3d.com/en/#!/content/60955?aid=1011lGnL. This asset is only legally available from the Unity Asset Store.
// 
// I'm a single indie dev supporting my family by spending hundreds and thousands of hours on this and other assets. It's very offensive, rude and just plain evil to steal when I (and many others) put so much hard work into the software.
// 
// Thank you.
//
// *** END NOTE ABOUT PIRACY ***
//

// Resources:
// http://library.nd.edu/documents/arch-lib/Unity/SB/Assets/SampleScenes/Shaders/Skybox-Procedural.shader
//

// TODO: Better sky: https://github.com/ngokevin/kframe/blob/master/components/sun-sky/shaders/fragment.glsl
// TODO: Better sky: https://threejs.org/examples/js/objects/Sky.js

Shader "WeatherMaker/WeatherMakerSkySphereShader"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "Queue" = "Geometry+1" }

		CGINCLUDE

		#pragma target 3.5
		#pragma exclude_renderers gles
		#pragma exclude_renderers d3d9

		#define WEATHER_MAKER_ENABLE_TEXTURE_DEFINES

		#include "WeatherMakerSkyShaderInclude.cginc"
		#include "WeatherMakerAtmosphereShaderInclude.cginc"

		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma glsl_no_auto_normalization
		#pragma multi_compile_instancing

		uniform fixed _WeatherMakerSkyYOffset2D;

		static const float sunSkyFade = pow(_WeatherMakerSunColor.a, 0.5) * _WeatherMakerDirectionalLightScatterMultiplier * pow(saturate(_WorldSpaceCameraPos.y * _WeatherMakerSkyFade.z), 2.0);

		inline fixed4 SkyTexturedColor(fixed4 skyColor, fixed3 nightColor, fixed2 uv)
		{
			fixed4 dayColor = tex2D(_DayTex, uv) * _WeatherMakerDayMultiplier;
			fixed4 dawnDuskColor = tex2D(_DawnDuskTex, uv);
			fixed4 dawnDuskColor2 = dawnDuskColor * _WeatherMakerDawnDuskMultiplier;
			dayColor += dawnDuskColor2;

			// hide night texture wherever dawn/dusk is opaque, reduce if clouds
			nightColor *= (1.0 - dawnDuskColor.a);

			// blend texture on top of sky
			fixed4 result = ((dayColor * dayColor.a) + (skyColor * (1.0 - dayColor.a)));

			// blend previous result on top of night
			return ((result * result.a) + (fixed4(nightColor, 1.0) * (1.0 - result.a)));
		}

		inline fixed4 SkyNonTexturedColor(fixed4 skyColor, fixed3 nightColor)
		{
			return skyColor + fixed4(nightColor, 0.0);
		}

		fixed4 fragBase(wm_volumetric_data i)
		{
			WM_INSTANCE_FRAG(i);

			//return tex2D(_NightTex, i.uv);

			fixed4 result = fixed4Zero;
			float3 origRay = normalize(i.rayDir.xyz);
			float3 rayDir = i.rayDir;

			// if Unity style sky, mirror sky, the ground looks bad
			//rayDir.y = lerp(rayDir.y, abs(rayDir.y), (WM_ENABLE_PROCEDURAL_TEXTURED_SKY || WM_ENABLE_PROCEDURAL_SKY));

			rayDir.y = (rayDir.y + 10.0 + _WeatherMakerSkyYOffset2D);
			rayDir = normalize(rayDir);
			fixed4 skyColor;
			fixed3 nightColor;
			fixed sunMoon;

			// use depth buffer and camera frustum to get an exact world position and take that distance from the camera
			float2 screenUV = i.projPos.xy / max(0.0001, i.projPos.w);
			float rawDepth = WM_SAMPLE_DEPTH(screenUV);
			float depth01 = Linear01Depth(rawDepth);
			float depth = LinearEyeDepth(rawDepth);
			float worldDistance01 = min(1.0, (depth / abs(normalize(i.viewPos).z)) * _ProjectionParams.w);
			float rayYFade = min(1.0, 2.0 * (1.0 - abs(origRay.y)));
			float depthFade = saturate(1.5 * ((depth01 >= 0.99999) + (((worldDistance01 - _WeatherMakerSkyFade.x) * _WeatherMakerSkyFade.y) * sunSkyFade * rayYFade)));

			//return fixed4(depth01.xxx, 1.0);
			//return fixed4(worldDistance01.rrr, 1.0);
			//return fixed4(rayDir, 1.0);

			UNITY_BRANCH
			if (depthFade > 0.00001)
			{
				UNITY_BRANCH
				if (WM_ENABLE_PROCEDURAL_TEXTURED_SKY || WM_ENABLE_PROCEDURAL_SKY || WM_ENABLE_PROCEDURAL_SKY_ATMOSPHERE || WM_ENABLE_PROCEDURAL_TEXTURED_SKY_ATMOSPHERE)
				{
					fixed4 skyColor;
					UNITY_BRANCH
					if (WM_ENABLE_PROCEDURAL_TEXTURED_SKY || WM_ENABLE_PROCEDURAL_SKY)
					{
						procedural_sky_info sky = CalculateScatteringCoefficients(_WeatherMakerSunDirectionUp, _WeatherMakerSunColor.rgb, 1.0, rayDir);
						procedural_sky_info sky2 = CalculateScatteringColor(_WeatherMakerSunDirectionUp, _WeatherMakerSunColor.rgb, _WeatherMakerSunVar1.x, rayDir, sky.inScatter, sky.outScatter);
						skyColor.rgb = sky2.skyColor.rgb;
					}
					else
					{
						skyColor.rgb = ComputeAtmosphericScatteringSkyColor(rayDir);
					}
					skyColor.rgb *= _WeatherMakerSkyTintColor;
					skyColor.a = min(1.0, _NightDuskMultiplier * max(skyColor.r, max(skyColor.g, skyColor.b)));
					nightColor = GetNightColor(rayDir, i.uv, skyColor.a);
					UNITY_BRANCH
					if (WM_ENABLE_PROCEDURAL_TEXTURED_SKY)
					{
						result = SkyTexturedColor(skyColor, nightColor, i.uv);
					}
					else
					{
						result = SkyNonTexturedColor(skyColor, nightColor);
					}
				}
				else // WM_ENABLE_TEXTURED_SKY
				{
					nightColor = GetNightColor(rayDir, i.uv, 0.0);
					fixed4 dayColor = tex2D(_DayTex, i.uv) * _WeatherMakerDayMultiplier;
					fixed4 dawnDuskColor = (tex2D(_DawnDuskTex, i.uv) * _WeatherMakerDawnDuskMultiplier);
					result = (dayColor + dawnDuskColor + fixed4(nightColor, 0.0));
				}
				ApplyDither(result.rgb, origRay, _WeatherMakerSkyDitherLevel);
				result.a = depthFade;
			}
			return result;
		}

		fixed4 frag(wm_volumetric_data i) : SV_Target
		{
			return fragBase(i);
		}

		ENDCG

		Pass
		{
			Tags { }
			Cull Front Lighting Off ZWrite Off ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex GetVolumetricData
			#pragma fragment frag

			ENDCG
		}
	}

	FallBack Off
}

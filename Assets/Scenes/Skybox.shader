Shader "Unlit/Skybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Sun Settings)]
        _SunRadius("Sun Radius", float) = 1.0
        _SunColor("Sun Color", color) = (1,1,1,1)
        
        [Header(Moon Settings)]
        _MoonRadius("Moon Radius", float) = 0.1
        _MoonOffset("Moon Crescent Offset", float) = -0.1
        _MoonColor("Moon Color", color) = (1,1,1,1)
        
        [Header(Sky Gradient Settings)]
        _DayGradTop("Day Sky Color Top", color) = (0.4,1,1,1)
        _DayGradBot("Day Sky Color Bottom", color) = (0,0.8,1,1)
        _NightGradTop("Night Gradient Top", color) = (0.1,0,0.3,1)
        _NightGradBot("Night Gradient Bottom", color) = (0.025,0,0.1,1)
        
        [Header(Horizon Settings)]
        _HorizonDay("Horizon Color Day", color) = (0.9, 0.5, 0.43,1)
        _HorizonNight("Horizon Color Night", color) = (0.025,0,0.1,1)
        _HorizonIntensity("Horizon Intensity",  Range(0, 10)) = 3.3
        _OffsetHorizon("Horizon Offset",  Range(-1, 1)) = 0
        
        [Header(Star Settings)]
        _Stars("Star Texture", 2D) = "white" {}
        _StarsMoveSpeed("Stars Move Speed", float) = 0.1
        _StarsCutoff("Stars Alpha Cutoff", Range(0.0,1.0)) = 0.1
        _StarsSkyColor("Stars Sky Color", Color) = (0.0,0.0,0.8,1)
        
        [Header(Cloud Settings)]
        _CloudTex("Cloud Texture", 2D) = "white" {}
        _CloudDistortTex("Cloud Distort Texture", 2D) = "white" {}
        _CloudSecondaryTex("Cloud Secondary Texture", 2D) = "white" {}
        _CloudTexScale("_CloudTexScale", Range(0.0,1.0)) = 0.2
        _CloudDistortScale("_CloudDistortScale", Range(0.0,1.0)) = 0.06
        _CloudSecondaryScale("_CloudSecondaryScale", Range(0.0,1.0)) = 0.05
        _CloudExtraDistortion("_CloudExtraDistortion", Range(0,1)) = 0.1
        _CloudSpeed("_CloudSpeed", Range(0,10)) = 1.4
        _CloudCutoff("_CloudCutoff", Range(0.0,1.0)) = 0.3
        _Fuzziness("_Fuzziness",  Range(0, 1)) = 0.04
        _FuzzinessUnder("_FuzzinessUnder",  Range(0, 1)) = 0.01
        _CloudColorDayEdge("Clouds Edge Day", Color) = (1,1,1,1)
        _CloudColorDayMain("Clouds Main Day", Color) = (0.8,0.9,0.8,1)
        _CloudColorDayUnder("Clouds Under Day", Color) = (0.6,0.7,0.6,1)
        _CloudColorNightEdge("Clouds Edge Night", Color) = (0,1,1,1)
        _CloudColorNightMain("Clouds Main Night", Color) = (0,0.2,0.8,1)
        _CloudColorNightUnder("Clouds Under Night", Color) = (0,0.2,0.6,1)
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex, _Stars, _CloudTex,_CloudDistortTex,_CloudSecondaryTex;
            float4 _MainTex_ST;
            float _SunRadius, _MoonRadius, _CrescentRadius, _MoonOffset;
            float4 _SunColor, _MoonColor, _DayGradTop,_DayGradBot,_NightGradTop,_NightGradBot;
            float4 _HorizonDay, _HorizonNight, _StarsSkyColor;
            float _StarsMoveSpeed, _StarsCutoff;
            float _CloudTexScale,_CloudDistortScale,_CloudSecondaryScale,_CloudExtraDistortion,_CloudSpeed,_CloudCutoff, _Fuzziness, _FuzzinessUnder;
            float4 _CloudColorDayEdge, _CloudColorDayMain, _CloudColorDayUnder;
            float4 _CloudColorNightEdge, _CloudColorNightMain, _CloudColorNightUnder;
            float _HorizonIntensity, _OffsetHorizon;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float horizon = abs((i.uv.y*_HorizonIntensity) - _OffsetHorizon);
                float2 skyUV = i.worldPos.xz/i.worldPos.y;


                float baseClouds = tex2D(_CloudTex, (skyUV - _Time.x)*_CloudTexScale).x;
                float noise1 = tex2D(_CloudDistortTex, ((skyUV + baseClouds) - (_Time.x*_CloudSpeed))*_CloudDistortScale);
                float noise2 = tex2D(_CloudSecondaryTex, ((skyUV+(noise1*_CloudExtraDistortion))-(_Time.x*_CloudSpeed*0.5))*_CloudSecondaryScale);
                float finalNoise = saturate(noise1*noise2)*3*saturate(i.worldPos.y);
                float clouds = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _Fuzziness, finalNoise));
                float cloudsUnder = saturate(smoothstep(_CloudCutoff, _CloudCutoff+_Fuzziness+_FuzzinessUnder, noise2)*clouds);
                float3 cloudsDayCol = lerp(_CloudColorDayEdge, lerp(_CloudColorDayUnder, _CloudColorDayMain, cloudsUnder), clouds)*clouds;
                float3 cloudsNightCol = lerp(_CloudColorNightEdge, lerp(_CloudColorNightUnder, _CloudColorNightMain, cloudsUnder), clouds)*clouds;
                cloudsNightCol *= horizon;
                float3 cloudsCol = lerp(cloudsNightCol, cloudsDayCol, saturate(_WorldSpaceLightPos0.y));
                float cloudsNegative = (1-clouds);
                
                float sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float sunDisc = 1 - saturate(sun/_SunRadius);
                sunDisc = saturate(sunDisc*50);

                float moon = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                float crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -_WorldSpaceLightPos0);
                float crescentMoonDisc = 1 - (crescentMoon/_MoonRadius);
                crescentMoonDisc = saturate(crescentMoonDisc*50);
                float moonDisc = 1 - (moon/_MoonRadius);
                moonDisc = saturate(moonDisc*50);
                moonDisc = saturate(moonDisc - crescentMoonDisc);
                moonDisc *= cloudsNegative;

                float3 sunAndMoon = (sunDisc*_SunColor) + (moonDisc*_MoonColor);

                float3 dayGrad = lerp(_DayGradBot, _DayGradTop, saturate(horizon));
                float3 nightGrad = lerp(_NightGradBot, _NightGradTop, saturate(horizon));
                float3 skyGrad = lerp(nightGrad, dayGrad, saturate(_WorldSpaceLightPos0.y));

                float horizonDay = saturate((1-horizon*5)*saturate(_WorldSpaceLightPos0.y*10));
                float horizonNight = saturate((1-horizon*5)*saturate(-_WorldSpaceLightPos0.y*10));
                float4 horizonGlow = horizonDay * _HorizonDay + horizonNight * _HorizonNight;

                float3 stars = tex2D(_Stars, skyUV + _StarsMoveSpeed * _Time.x);
                stars *= saturate(-_WorldSpaceLightPos0.y);
                stars = step(_StarsCutoff, stars);
                
                
                return float4(sunAndMoon+skyGrad+stars+cloudsCol, 1) + horizonGlow;
            }
            ENDCG
        }
    }
}

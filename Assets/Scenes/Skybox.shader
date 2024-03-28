Shader "Unlit/Skybox"
{
    Properties
    {
        _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
        [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
        _Rotation ("Rotation", Range(0, 360)) = 0
        [NoScaleOffset] _Tex ("Cubemap   (HDR)", Cube) = "grey" {}
        _Voronoi ("Voronoi", 2D) = "white" {}
        [MaterialToggle] _DebugUV ("Debug UV", float) = 0.0
        _HorizonColor ("Horizon Color", Color) = (0,0,0,0)
        _SkyColor ("Sky Color", Color) = (0,0,0,0)
        _StarPower ("Star Power", float) = 0.0 
        _YShift ("Y Shift", Range(-1,1)) = 0.0
        _XMod("X Mod", Range(0,1)) = 0.0
        _YMod("Y Mod", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox"
        }
        Cull Off ZWrite Off

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"

            samplerCUBE _Tex;
            half4 _Tex_HDR;
            half4 _Tint;
            half _Exposure;
            float _Rotation;

            sampler2D _Voronoi;
            float4 _Voronoi_ST;

            float _DebugUV;
            float4 _HorizonColor;
            float4 _SkyColor;
            float _StarPower;

            float _YShift;
            float _XMod;
            float _YMod;

            float3 RotateAroundYInDegrees(float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }
            float2 SkyboxUV(float4 worldPos)
            {
                float3 pos = worldPos.xyz ;
                pos = normalize(pos);
                float x = atan2(pos.x,pos.z)/UNITY_TWO_PI;
                float y = asin(pos.y)/UNITY_HALF_PI;
                return float2(x,y);
            }
            float4 StarLayer(float2 uv, float2 tiling, float2 offset)
            {
                fixed4 stars = tex2D(_Voronoi, uv*tiling + offset);
                stars = saturate(stars);
                stars = 1 - stars;
                stars = pow(stars, _StarPower);
                stars *= _Exposure;
                return stars;
            }
            struct appdata_t
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
                float3 viewDir : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float2 uvSky : TEXCOORD3;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 rotated = RotateAroundYInDegrees(v.vertex, _Rotation);
                o.vertex = UnityObjectToClipPos(rotated);
                o.texcoord = v.vertex.xyz;

                float4x4 modelMatrix = unity_ObjectToWorld;
                o.viewDir = mul(modelMatrix, v.vertex).xyz - _WorldSpaceCameraPos;
                o.worldPos = mul(modelMatrix, v.vertex);
                o.uvSky = SkyboxUV(o.worldPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 output;
                fixed4 c = fixed4(0,0,0,0);
                if(_DebugUV >= 0.5)
                {
                    fixed4 tex = texCUBE(_Tex, i.texcoord);
                    c.xyz = DecodeHDR(tex, _Tex_HDR);
                    c.xyz = c.xyz * _Tint.rgb * unity_ColorSpaceDouble.rgb;
                    c.xyz *= _Exposure;
                    return half4(c.xyz, 1);
                }
                c = lerp(_HorizonColor, _SkyColor, i.uvSky.y-_YShift);
                fixed4 starLayer1 = StarLayer(i.uvSky.xy, _Voronoi_ST.xy, _Voronoi_ST.zw);
                fixed4 starLayer2 = StarLayer(i.uvSky.yx, _Voronoi_ST.yx, _Voronoi_ST.zw);
                output = c+starLayer1+starLayer2;
                return output;
            }
            ENDCG
        }
    }


    Fallback Off
}
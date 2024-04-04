Shader "Unlit/Water"
{
	Properties
	{
		_CausticTex("Caustics Texture", 2D) = "white" {}
		_maxFrames("max frames", float) = 8.0
		_frame("anim frame", float) = 0.0
		_animSpeed("anim speed", float) = 0.0
		_Roughness("Roughness", Range(0.0, 10.0)) = 0.0
	}

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

			float _Roughness;
            sampler2D _CausticTex;
            float4 _CausticTex_ST;
            float _maxFrames, _frame, _animSpeed;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

            struct v2f 
			{
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
            	o.uv = TRANSFORM_TEX(v.uv, _CausticTex);
                return o;
            }
        
            fixed4 frag (v2f i) : SV_Target
            {
            	float currentTime = _Time.y*_animSpeed;
            	float2 uv = (i.uv % 1/_maxFrames) + (floor(currentTime) % _maxFrames)/_maxFrames;
            	float2 nextUV = (i.uv % 1/_maxFrames) + (floor(currentTime+1) % _maxFrames)/_maxFrames;
            	float4 causticsColor = tex2D(_CausticTex, uv);
            	float4 nextCausticsColor = tex2D(_CausticTex, nextUV);
            	float4 causticLerpColor = lerp(causticsColor, nextCausticsColor, 0.5);
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //Direction of ray from the camera towards the object surface
                half3 reflection = reflect(-worldViewDir, i.worldNormal); // Direction of ray after hitting the surface of object
				/*If Roughness feature is not needed : UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection) can be used instead.
				It chooses the correct LOD value based on camera distance*/
                half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, _Roughness);
                half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR); // This is done becasue the cubemap is stored HDR
                //return half4(skyColor, 1.0);
            	return saturate((half4(skyColor, 1.0) + causticLerpColor));
            }
            ENDCG
        }
    }
}

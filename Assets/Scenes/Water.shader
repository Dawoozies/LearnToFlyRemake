Shader "Unlit/Water"
{
	Properties
	{
		_ReflectionMap("Reflection Render Texture", Cube) = "white" {}
		_CausticTex("Caustics Texture", 2D) = "white" {}
		_DistortionTex("Vertex Distortion Texture", 2D) = "white" {}
		_animSpeed("UV Distortion Speed", float) = 1.0
		_distortionRadius("UV Distortion Radius", Range(0,1)) = 0.1
		_Speed("Wave Speed", float) = 0.5
		_Amount("Wave Amount", float) = 0.5
		_Height("Wave Height", Range(0,1)) = 0.5
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
            sampler2D _CausticTex, _DistortionTex;
            float4 _CausticTex_ST, _DistortionTex_ST;
            float _animSpeed, _distortionRadius;
            float _Speed, _Amount, _Height;
            samplerCUBE _ReflectionMap;

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
            	float2 distortionUV : TEXCOORD3;
            };


            v2f vert (appdata v)
            {
                v2f o;
				float4 distTex = tex2Dlod(_DistortionTex, float4(v.uv.xy,0,0));
            	//v.vertex.x += cos(_Time.z*_Speed + (v.vertex.y*_Amount*distTex))*_Height;
				//v.vertex.x += cos(_Time.z*_Speed + (v.vertex.x*_Amount*distTex))*_Height;
            	//v.vertex.y += sin(_Time.z*_Speed + (v.vertex.y*_Amount*distTex))*_Height;
            	v.vertex.z += sin(_Time.z*_Speed + (v.vertex.x*v.vertex.y*_Amount*distTex))*_Height;

            	o.uv = TRANSFORM_TEX(v.uv, _CausticTex);
            	o.distortionUV = TRANSFORM_TEX(v.uv, _DistortionTex);
                o.pos = UnityObjectToClipPos(v.vertex);
            	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
        
            fixed4 frag (v2f i) : SV_Target
            {
            	float currentTime = (_Time.y*_animSpeed)%1;
            	float2 distortionUV = i.distortionUV - currentTime;
            	float4 distortionTexSample = tex2D(_DistortionTex, distortionUV);
            	//First method:
            	//distort uv in just y by radius just using the red channel
            	//white = _distortionRadius black = 0
            	//float2 uvDistortion = lerp(0, _distortionRadius, distortionTexSample.r);

            	//Second method
            	//distort uv by adding nearby point on circle
            	float2 uvDistortion = _distortionRadius*float2(cos(distortionTexSample.r*UNITY_TWO_PI), sin(distortionTexSample.r*UNITY_TWO_PI));
            	float2 uv = i.uv + uvDistortion.x;
            	float2 nextUV = i.uv - uvDistortion.y;

            	float4 causticsColor = tex2D(_CausticTex, uv*_CausticTex_ST.xy + _CausticTex_ST.zw);
            	float4 nextCausticsColor = tex2D(_CausticTex, nextUV*_CausticTex_ST.xy + _CausticTex_ST.zw);
            	float4 causticLerpColor = lerp(causticsColor, nextCausticsColor, 0);
				
				
            	
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //Direction of ray from the camera towards the object surface
                half3 reflection = reflect(-worldViewDir, i.worldNormal); // Direction of ray after hitting the surface of object
				/*If Roughness feature is not needed : UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection) can be used instead.
				It chooses the correct LOD value based on camera distance*/
                //half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, _Roughness);
            	half3 skyColor = texCUBE(_ReflectionMap, reflection);
                //half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR); // This is done becasue the cubemap is stored HDR
                //return half4(skyColor, 1.0);
            	//return half4(skyColor, 1.0) + causticLerpColor;
            	float normPosDot = saturate(dot(i.worldNormal,i.worldPos));
            	float4 reflectionCol = half4(skyColor,1.0);
            	float4 darkCol = dot(causticLerpColor,skyColor);
            	float4 col = darkCol+reflectionCol;
            	return col;
            }
            ENDCG
        }
    }
}

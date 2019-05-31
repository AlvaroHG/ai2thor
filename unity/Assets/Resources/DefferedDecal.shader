﻿
Shader "Custom/DiffuseDecal" {
    Properties 
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        // Tags { "RenderType"="Opaque" }

        Tags {
                "RenderType"="Opaque"
				"LightMode" = "Deferred"
			}
       
        Pass
        {

            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            struct v2f
            {
                float4 pos : SV_POSITION;
               
                float4 sreenPos : TEXCOORD1;
                float3 rayToCamera : TEXCOORD2;
                // float4 clipPos: TEXCOORD2;
            };
           
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.sreenPos = ComputeScreenPos(o.pos);
  
                o.rayToCamera = mul(UNITY_MATRIX_MV, float4(v.vertex.xyz, 1)).xyz * float3(-1, -1, 1);


                return o;
            }

            CBUFFER_START(UnityPerCamera2)
			// float4x4 _CameraToWorld;
			CBUFFER_END
           
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4x4 _inverseMVP;
            half _Emissiveness;

            float pointInUnitaryCube(float4 positionObjectSpace) {
                // Faster version of 
                // if (positionObjectSpace.xyz > -0.5 && positionObjectSpace.xyz < 0.5)
                // Checking if xyz coordinates are inside of a unitary cube with it's center as it's space's 0,0,0
                float3 stepVec = step(-0.5, positionObjectSpace.xyz) * step(positionObjectSpace.xyz, 0.5);
                return stepVec.x * stepVec.y * stepVec.z;
               
            }
 
            fixed4 frag (v2f i) : SV_Target
            {
                // float2 uv = i.sreenPos.xy / i.sreenPos.w;
                i.rayToCamera = i.rayToCamera * (_ProjectionParams.z / i.rayToCamera.z);
               
                float depth = Linear01Depth(tex2Dproj(_CameraDepthTexture, i.sreenPos));

                float4 cameraSpacePos = float4(i.rayToCamera * depth, 1.0);
                float3 worldPos = mul(unity_CameraToWorld, cameraSpacePos);
                float3 objectPos = mul(unity_WorldToObject, float4(worldPos, 1));


                //float inside = pointInUnitaryCube(mul(_inverseMVP, i.sreenPos));
                //float depth01 = tex2Dproj(_CameraDepthTexture, i.sreenPos);
                
                // float inside = pointInUnitaryCube(mul(_inverseMVP, screenPosDepth));
                // float4 objectSpacePos = mul(_inverseMVP, screenPosDepth);
                clip(float3(0.5, 0.5, 0.5) - abs(objectPos.xyz));

            // float lowBits = floor(depth01 * 256) / 256;
			// 	 float medBits = 256 * (depth01 - lowBits);
			// 	 medBits = floor(256 * medBits) / 256;
			// 	 float highBits = 256 * 256 * (depth01 - lowBits - medBits / 256);
			//   	 highBits = floor(256 * highBits) / 256;

			//     return fixed4(lowBits, medBits, highBits, 1.0);

                // return fixed4(depth, depth, depth, 1);
                fixed4 color = tex2D(_MainTex, float2(-(objectPos.x + 0.5), objectPos.y + 0.5));
                // float depthColor = 1 - depth;
                // return depthColor;
                return color;
            }

            

            ENDCG
        }
    }
}
Shader "Custom/BlinnPongSpecular"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Shininess("Shininess",Range(2,128)) = 50
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="XForwardBase"}
        LOD 100

        Pass
        {

            HLSLPROGRAM
            
            #pragma vertex PassVertex
            #pragma fragment PassFragment
            #pragma enable_cbuffer
            #include "UnityCG.cginc"
            #include "./ShaderLibrary/Light.hlsl"
            #include "./ShaderLibrary/Shadow.hlsl"

            //UNITY_DECLARE_TEX2D(_XMainShadowMap);
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                float3 normalWS    : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                
            };

            UNITY_DECLARE_TEX2D(_MainTex);

            
            float _Shininess;
            float4 _MainTex_ST;
            float4 _SpecularColor;
 
           
            Varyings PassVertex(Attributes input)
            {
                Varyings output;
                output.positionCS = UnityObjectToClipPos(input.positionOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = mul(unity_ObjectToWorld, float4( input.normalOS, 0.0 )).xyz;
                output.positionWS = mul(unity_ObjectToWorld,input.positionOS).xyz;
                return output;
            }

            half4 PassFragment(Varyings input) : SV_Target
            {

                half4 diffuseColor = UNITY_SAMPLE_TEX2D(_MainTex,input.uv);
                float3 positionWS = input.positionWS;
                float3 normalWS = input.normalWS;
                diffuseColor.xyz = diffuseColor.xyz * LambertDiffuse(normalWS);
                half4 color = BlinnPongLight(positionWS, normalWS, _Shininess, diffuseColor, _SpecularColor);
                color += _XAmbientColor;
                float shadow = GetMainLightShadowAtten(positionWS,normalWS);
                return color*(1.0 - shadow);
                //return diffusec
            }
            ENDHLSL
        }

        Pass
        {
           Name "ShadowCaster"
           Tags{"LightMode" = "ShadowCaster"}

           ZWrite On
           ZTest LEqual
           ColorMask 0
           Cull Back

           HLSLPROGRAM
           #include "UnityCG.cginc"
           #include "./ShaderLibrary/Shadow.hlsl"
            #pragma vertex ShadowCasterVertex
            #pragma fragment ShadowCasterFragment

            ENDHLSL
        }
    }
}

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
            //#include "../ShaderLibrary/Light.hlsl"



            half4 _XAmbientColor;
            //主灯光方向
            float4 _XMainLightDirection;
            //主灯光颜色
            half4 _XMainLightColor;


  

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

            half LambertDiffuse(float3 normal){
              //return max(0,dot(normal,_XMainLightDirection.xyz));
              float dotNL = dot(normal, _XMainLightDirection.xyz);
              dotNL = dotNL * 0.5 + 0.5;
              return dotNL;
            };

            float BilinnPhongSpecular(float3 viewDir, float3 normal, float shiness) {
                float3 halfDir = normalize((viewDir  + _XMainLightDirection));
                float dotHN = pow( max(0, dot(halfDir, normal)), shiness);

                return dotHN;
            }


           half4 BlinnPhongLight(float3 positionWS, float3 normalWS, float shiness, half diffuseColor, half4 specularColor)
           {
               float3 viewDir = normalize( _WorldSpaceCameraPos - positionWS);
               return BilinnPhongSpecular(viewDir, normalWS, shiness) * specularColor;
           }
        

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
                half4 color = BlinnPhongLight(positionWS, normalWS, _Shininess, diffuseColor, float4(1.0, 0, 0, 1.0));
                return color + diffuseColor + _XAmbientColor;
            }
            ENDHLSL
        }
    }
}

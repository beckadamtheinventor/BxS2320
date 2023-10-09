Shader "BeckATI/BxS2320/DebugTTY"
{
    Properties
    {
        _MainTex ("Emulator CRT", 2D) = "black" {}
		_FontTex ("Font Image", 2D) = "black" {}
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
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				UNITY_VERTEX_OUTPUT_STEREO
            };

            texture2D<uint4> _MainTex;
            sampler2D _FontTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				uint tx = i.uv.x * 256.0;
				uint ty = i.uv.y * 256.0;
				uint tix = tx & 7;
				uint tiy = ty & 7;
				tx = tx >> 3;
				ty = ty >> 3;
				uint chr;
				uint rno = i.uv.y * 256 / 8.0f;
				int x = i.uv.x * 256 / 8.0f;
				chr = (x==0?'r':(x==1?(rno>>4)&0xf:(x==2?(rno&0xf):(x==3?'=':(x<12?((_MainTex[uint2(rno, 0xff)].b >> (32 - (x-3)*4)) & 0xf):' ')))));
				x = i.uv.x * 256 / 8.0f - 16;
				chr = x>=0?(x==7?' ':((_MainTex[uint2(rno+32*step(8, x), 0xff)].g >> (28 - ((x>7?(x-1):x)&7)*4)) & 0xf)):chr;
				chr = chr<16?(chr+0x30+7*step(10, chr)):chr;
				uint tcx = ((chr & 0xf) << 3) + tix;
				uint tcy = 120 - ((chr >> 4) << 3) + tiy;
				fixed4 col = tex2D(_FontTex, float2(tcx / 128.0f, tcy / 128.0f));
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}

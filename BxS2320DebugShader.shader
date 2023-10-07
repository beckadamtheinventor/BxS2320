Shader "BeckATI/BxS2320/DebugTTY"
{
    Properties
    {
        _MainTex ("Emulator CRT", 2D) = "black" {}
		_ImageSizeBits("Memory View Size Bits", Int) = 8
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
			uint _ImageSizeBits;

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
				uint chr = ' ', tint = 0;
				uint rno = i.uv.y * 256 / 8.0f;
				if (i.uv.x < 8*12 / 256.0f) {
					uint x = i.uv.x * 256 / 8.0f;
					if (x == 0)
						chr = 'r';
					else if (x == 1)
						chr = (rno >> 4) & 0xf;
					else if (x == 2)
						chr = rno & 0xf;
					else if (x == 3)
						chr = '=';
					else {
						chr = (_MainTex[uint2(rno, 255)].b >> (32 - (x-3)*4)) & 0xf;
					}
				} else if (i.uv.x >= 0.5f) {
					uint x = (i.uv.x - 0.5f) * 256 / 8.0f;
					if (x < 8) {
						chr = (_MainTex[uint2(rno, 255)].g >> (28 - x*4)) & 0xf;
					} else {
						chr = (_MainTex[uint2(rno+32, 255)].g >> (28 - (x-8)*4)) & 0xf;
					}
				}

				if (chr < 16) {
					if (chr >= 10)
						chr += 0x41 - 10;
					else
						chr += 0x30;
				}
				uint tcx = ((chr & 0xf) << 3) + tix;
				uint tcy = 120 - ((chr >> 4) << 3) + tiy;
				uint invert = (tint & 0x40);
				float tintr = (((tint >> 4) & 3) + 1) / 3;
				float tintg = (((tint >> 2) & 3) + 1) / 3;
				float tintb = (((tint >> 0) & 3) + 1) / 3;
				fixed4 col = tex2D(_FontTex, float2(tcx / 128.0f, tcy / 128.0f));
				if (tint > 0) {
					if (invert) {
						col.r = 1 - col.r;
						col.g = 1 - col.g;
						col.b = 1 - col.b;
					}
					col.r *= tintr;
					col.g *= tintg;
					col.b *= tintb;
				}
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
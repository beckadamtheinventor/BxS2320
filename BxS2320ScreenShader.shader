Shader "BeckATI/BxS2320/Display"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Emulator CRT", 2D) = "black" {}
		_OutputSize("Display size in pixels", Float) = 128
		_OutputMargin("Output Margin", Float) = 0.01
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass {
				CGPROGRAM

				#pragma fragment frag
				#pragma vertex vert
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

				struct Input
				{
					float2 uv_MainTex;
				};

				Texture2D<uint4> _MainTex;
				float4 _MainTex_ST;
				fixed4 _Color;

				float _OutputSize;
				float _OutputMargin;

				v2f vert(appdata v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_OUTPUT(v2f, o);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}

	#define read(a, c) _MainTex[uint2(uint(a) & 0xff, uint(a) >> 8)].c
	#define readbyte(a, c) (read(a, c) & 0xff)
	#define _CharSizeX 8
	#define _CharSizeY 8

				fixed4 frag(v2f i) : SV_TARGET
				{
					float ftx = (i.uv.x * (1.0f + _OutputMargin) - 0.5f * _OutputMargin) * _OutputSize;
					float fty = (1.0f - (i.uv.y * (1.0f + _OutputMargin) - 0.5f * _OutputMargin)) * _OutputSize;
					fixed4 col = fixed4(0, 0, 0, 1);
					if (ftx >= 0 && ftx < _OutputSize && fty >= 0 && fty < _OutputSize) {
						uint tcx = ftx % _CharSizeX;
						uint tcy = fty % _CharSizeY;
						uint tx = ftx / _CharSizeX;
						uint ty = fty / _CharSizeY;
						uint dflags = read(0xffff, r);
						if (dflags & 0x8000) {
							uint tp = tx + ty * _OutputSize / _CharSizeX;
							uint chr = read(0xff00+tp, g);
							uint chrp = read(0xfffe, r) + (chr & 0xff) * 8;
							uint c = (readbyte(chrp + tcy, r) >> ((_CharSizeX-1) - tcx)) & 1;
							if (dflags & 0x4000) {
								chr ^= 0x80000000;
							}
							if (chr & 0x80000000) {
								c = 1 - c;
							}
							col = fixed4(c, c, c, 1) * _Color;
							float tintr = (((chr >> 26) & 31) + 1) / 32.0f;
							float tintg = (((chr >> 21) & 31) + 1) / 32.0f;
							float tintb = (((chr >> 16) & 31) + 1) / 32.0f;
							col.rgb *= fixed3(tintr, tintg, tintb);
						}
					}
					return col;
				}
				ENDCG
			}
		}
}


StructuredBuffer<float3> sbPos;
StructuredBuffer<float2> sbSize;
StructuredBuffer<float4> sbColor;

int SizeCount=1;
int ColorCount=1;

Texture2D tex0 <string uiname="Texture";>;

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerDraw : register(b0)
{
	float4x4 tVP:VIEWPROJECTION;
	float4x4 tV:VIEW;
	float4x4 tVI:VIEWINVERSE;
	float4x4 tP:PROJECTION;
	 
	uint PositionStartIndex;
	uint SizeStartIndex;
	uint ColorStartIndex;
	
	float4x4 tTex <string uiname="Texture Transform";>;
	float3 UpVector={0,1,0};
};

cbuffer cbPerObject : register(b1)
{
    float4x4 tW : WORLD;
    uint di : DRAWINDEX;
}

struct VS_IN
{
	uint vi : SV_VertexID;
};

struct VS_OUT
{
	float4 PosWVP:SV_POSITION;
	float2 TexCd:TEXCOORD0;
	float4 PosW:TEXCOORD1;
	float2 Size:TEXCOORD2;
	float4 Color:COLOR0;	
};

int PositionIndex(uint vi)
{
	return vi + PositionStartIndex;
}

int SizeIndex(uint vi)
{
	return (vi % SizeCount) + SizeStartIndex;
}

int ColorIndex(uint vi)
{
	return (vi % ColorCount) + ColorStartIndex;
}

VS_OUT VS(VS_IN In)
{
	VS_OUT Out=(VS_OUT)0;
	
	uint vi = In.vi;
	float3 p = sbPos[PositionIndex(vi)];
	
	float4 PosW = mul(float4(p, 1),tW);
	
	Out.PosW = PosW;
	Out.PosWVP = mul(PosW,tVP);
	Out.TexCd = 0;
	Out.Size = sbSize[SizeIndex(vi)];
	Out.Color = sbColor[ColorIndex(vi)];
	return Out;
}

float2 g_positions[4]:IMMUTABLE ={{-1,1},{1,1},{-1,-1},{1,-1}};
float2 g_texcoords[4]:IMMUTABLE ={{0,0},{1,0},{0,1},{1,1}};

[maxvertexcount(4)]
void gsSPRITE(point VS_OUT In[1], inout TriangleStream<VS_OUT> SpriteStream)
{
    VS_OUT Out = In[0];
	
	for(int i=0;i<4;i++)
	{
		//Out.TexCd=g_texcoords[i];
		Out.TexCd = (float4((g_texcoords[i].xy*2-1)*float2(1,-1),0,1)).xy*float2(1,-1)*.5+.5;
		Out.PosWVP = mul(float4(In[0].PosW.xyz+mul(float4(g_positions[i]*In[0].Size,0, 1).xyz, (float3x3)tVI),1), tVP);
		SpriteStream.Append(Out);
	}
}

[maxvertexcount(1)]
void gsPOINT(point VS_OUT In[1], inout PointStream<VS_OUT>GSOut)
{
	VS_OUT Out;	
	Out = In[0];
	Out.TexCd = mul(float4(0.5,0.5,0,1),tTex).xy*float2(1,-1)*.5+.5;
	GSOut.Append(Out);
}

float4 PS(VS_OUT In):SV_Target{
	float4 col = tex0.SampleLevel(g_samLinear,In.TexCd.xy,0);
	col *= In.Color;
	col.a *= saturate(dot(col.rgb, col.rgb));
	if(col.a <= 0.015) discard;
	return col;
}

technique10 Sprite{
	pass P0{
		SetVertexShader(CompileShader(vs_4_0,VS()));
		SetGeometryShader(CompileShader(gs_4_0,gsSPRITE()));
		SetPixelShader(CompileShader(ps_4_0,PS()));
	}
}

technique10 Point{
	pass P0{
		SetVertexShader(CompileShader(vs_4_0,VS()));
		SetGeometryShader(CompileShader(gs_4_0,gsPOINT()));
		SetPixelShader(CompileShader(ps_4_0,PS()));
	}
}




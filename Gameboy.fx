uniform float Power <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 2.0;
> = 1.25;

uniform float Mult <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 2.0;
> = 1.25;

uniform float Mix <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform float Desaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform float Dithering <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform float DitheringReduction <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.75;
> = 0.0;

uniform int PixelSize <
	ui_type = "drag";
	ui_min = 1; ui_max = 8;
> = 1;

#include "ReShade.fxh"

static float3 color1 = float3(8.0f / 255.f, 25.f / 255.f, 32.f / 255.f);
static float3 color2 = float3(50.f / 255.f, 106.f / 255.f, 79.f / 255.f);
static float3 color3 = float3(137.f / 255.f, 192.f / 255.f, 111.f / 255.f);
static float3 color4 = float3(223.f / 255.f, 246.f / 255.f, 208.f / 255.f);

float3 GameboyPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 uv = float2(
		floor(vois.x / PixelSize) * PixelSize / BUFFER_WIDTH,
		floor(vois.y / PixelSize) * PixelSize / BUFFER_HEIGHT
	);
	float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	float luma = pow(dot(col, float3(0.299f, 0.587f, 0.114f)) * Mult, Power);
	
	if (Dithering < 0.5f) {
		int level = int(min(4.0, max(0.0, floor(luma * 5.0f))));

		if (level == 0) col = lerp(col, color1, Mix);
		else if (level == 1) col = lerp(col, color2, Mix);
		else if (level == 2) col = lerp(col, color3, Mix);
		else col = lerp(col, color4, Mix);
	
		col = lerp(col, float3(float(level) / 4., float(level) / 4., float(level) / 4.), Desaturation);
	} else {
	    luma = min(7.0, max(1.0, luma * 7.0f));
		int level = int(ceil(luma));
		
		float checkDither = (floor(vois.x / PixelSize) + floor(vois.y / PixelSize)) % 2.0;
		float ditherTrigger = luma % 2.0f;
		
		if (ditherTrigger < 1.0f) {
			if (ditherTrigger < DitheringReduction / 2.0f) {
				level -= 1;
			} else if (ditherTrigger > 1.0f - DitheringReduction / 2.0f) {
				level += 1;
			} else {
				level += (1 - int(checkDither) * 2);
			}
		}
		
		if (level <= 1) col = lerp(col, color1, Mix);
		else if (level <= 3) col = lerp(col, color2, Mix);
		else if (level <= 5) col = lerp(col, color3, Mix);
		else col = lerp(col, color4, Mix);
		
		col = lerp(col, float3(float(level) / 7., float(level) / 7., float(level) / 7.), Desaturation);
	}
	
	return col;
}

technique Gameboy
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GameboyPass;
	}
}

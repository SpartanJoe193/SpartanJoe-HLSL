

PARAM_SAMPLER_2D(warp_map);
PARAM(float4, warp_map_xform);
PARAM(float, warp_amount_x);
PARAM(float, warp_amount_y);


void calc_warp_from_texture_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	float2 warp = sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy;
	warp = 2*max(warp, 0.0)-1;
	parallax_texcoord= texcoord + sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy * float2(warp_amount_x, warp_amount_y);
}

PARAM_SAMPLER_2D(warp_map2);
PARAM(float4, warp_map2_xform);

void calc_warp_from_two_texture_ps(
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{
	float2 diff = sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy - sample2D(warp_map2, transform_texcoord(texcoord, warp_map2_xform)).xy;
	parallax_texcoord= texcoord + (2*max(diff, 0.0)-1) * float2(warp_amount_x, warp_amount_y);
	
}

void calc_warp_from_two_texture_with_parallax_simple_ps(		// concocted specifically for my energy sword
	in float2 texcoord,
	in float3 view_dir,					// direction towards camera
	out float2 parallax_texcoord)
{

	float2 diff = sample2D(warp_map, transform_texcoord(texcoord, warp_map_xform)).xy - sample2D(warp_map2, transform_texcoord(texcoord, warp_map2_xform)).xy;
	float2 warp= texcoord + diff * float2(warp_amount_x, warp_amount_y);

	calc_parallax_simple_ps(warp, view_dir, parallax_texcoord);

}
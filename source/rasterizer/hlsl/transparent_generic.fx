#ifndef _TRANPSARENT_GENERIC_FX_
#define _TRANPSARENT_GENERIC_FX_

/*
=============================================
Created by SpartanJoe193
last modified on November 2nd, 2024 11:34 AM GMT+8
=============================================
*/

#include "additional_parameters.fx"

PARAM_SAMPLER_2D(plasma_mask_map);
PARAM(float4, plasma_mask_map_xform);
PARAM_SAMPLER_2D(plasma_offset_map);
PARAM(float4, plasma_offset_map_xform);
PARAM_SAMPLER_2D(plasma_noise_map_a);
PARAM(float4, plasma_noise_map_a_xform);
PARAM_SAMPLER_2D(plasma_noise_map_b);
PARAM(float4, plasma_noise_map_b_xform);

PARAM(float4, plasma_color);
PARAM(float3, plasma_flash_color);
PARAM(float, plasma_factor1);
PARAM(float, plasma_factor2);
PARAM(float, plasma_factor3);
PARAM(float, plasma_brightness);

PARAM(float4, color_medium_new);
PARAM(float4, color_sharp_new);
PARAM(float4, color_wide_new);
PARAM(float, thinness_medium_new);
PARAM(float, thinness_sharp_new);
PARAM(float, thinness_wide_new);

void calc_albedo_plasma_offset_advanced_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 T2 = 				sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform)).a;
	float T1 = 					sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform)).a;
	float T0 = 					sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform)).a;

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;
	float T3a = plasma_mask.a;


	/* Stage 0
	C0 = (0, 0, $plasma_factor2)
	C0a = $plasma_factor1

	R0= 	INVERT(C0a)*T2a + C0a*T0a
	R0a= 	INVERT(C0b)*1/2 + C0b*T1a
	*/
			float pre_plasma0 = lerp(T2, T0, plasma_factor1); // R0
			float pre_plasma1 = lerp(0.5, T1, plasma_factor2); // R0a

	/* Stage 1
	R0= 	T3*1/2 + INVERT(T3a)*R0
	R0a= 	T3a*1/2 + INVERT(T3a)*R0a
	*/
			float masked_plasma0 = T3a*0.5 + INVERT(T3a)*pre_plasma0 ; //R0
			float masked_plasma1 =  T3a*0.5 + INVERT(T3a)*pre_plasma1 ; // R0a

	/* Stage 2
	R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
	R0a= 	R0a + HALF_BIAS_NEGATIVE(R0b)
	*/

			float plasma_intermed0 = (masked_plasma0 + HALF_BIAS_NEGATIVE(masked_plasma1)); // R0
			float plasma_intermed1 = (masked_plasma1 + HALF_BIAS_NEGATIVE(masked_plasma0)); // R0a


	/* Stage 3
			C0a= $plasma_factor3

			T3=	T3*C0a
			R0a= (R0b*R0b mux R0a*R0a)

			If R0a is greater than than 0.5, CD is returned, else AB
	*/
			T3=			(T3*plasma_factor3);				// mask strength

			float plasma = plasma_intermed1 < 0.5 ? pow(plasma_intermed1, 2.0) : pow(plasma_intermed0, 2.0); // R0a
			plasma *= 4.0f;

			float plasma_proc = plasma < 0.5 ? 0 : EXPAND(plasma);


			float backgrounddiff = plasma < 0.5 ? 0 : EXPAND(plasma)*EXPAND(plasma);
				  backgrounddiff += backgrounddiff*INVERT(backgrounddiff);

			float medium_diff= pow(plasma_proc, thinness_medium_new);
				  medium_diff+= medium_diff*INVERT(medium_diff);

			float sharp_diff= pow(plasma_proc, thinness_sharp_new);
				  sharp_diff+= sharp_diff*INVERT(sharp_diff);

			float wide_diff= pow(plasma_proc, thinness_wide_new);
				  wide_diff+= wide_diff*INVERT(wide_diff);


			wide_diff-= medium_diff;
			medium_diff-= sharp_diff;
			
				
			albedo.rgb= 	(	medium_diff * backgrounddiff * T3 +
								medium_diff * color_medium_new.rgb*color_medium_new.a*T3 	+
								sharp_diff * color_sharp_new.rgb*color_sharp_new.a*T3 	+ 
								wide_diff * color_wide_new.rgb*color_wide_new.a*T3	
							)	+ color_wide_new*INVERT(T3a);

			albedo.rgb*= 	plasma_brightness;
			albedo.a = backgrounddiff + medium_diff + wide_diff + sharp_diff; // R0a


	//apply_pc_albedo_modifier(albedo, normal);
}


void calc_albedo_plasma_offset_legacy_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
		float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
		float4 T2 = 				sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform)).a;
		float T1 = 					sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform)).a;
		float T0 = 					sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform)).a;

	// This is Halo 1's Implementation, I was unable to create the color fade due to limitations in my HLSL knowledge

		/* Only the following parameters are used */
		
		float3 T3 = plasma_mask.rgb;
		float T3a = plasma_mask.a;
			
	/* Stage 0
	C0 = (0, 0, $plasma_factor2)
	C0a = $plasma_factor1

	R0= 	INVERT(C0a)*T2a + C0a*T0a
	R0a= 	INVERT(C0b)*1/2 + C0b*T1a
	*/
			float pre_plasma0 = lerp(T2, T0, plasma_factor1); // R0
			float pre_plasma1 = lerp(0.5, T1, plasma_factor2); // R0a

	/* Stage 1
	R0= 	T3*1/2 + INVERT(T3a)*R0
	R0a= 	T3a*1/2 + INVERT(T3a)*R0a
	*/
			float masked_plasma0 = T3a*0.5 + INVERT(T3a)*pre_plasma0 ; //R0
			float masked_plasma1 =  T3a*0.5 + INVERT(T3a)*pre_plasma1 ; // R0a

	/* Stage 2
	R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
	R0a= 	R0a + HALF_BIAS_NEGATIVE(R0b)
	*/

			float plasma_intermed0 = (masked_plasma0 + HALF_BIAS_NEGATIVE(masked_plasma1)); // R0
			float plasma_intermed1 = (masked_plasma1 + HALF_BIAS_NEGATIVE(masked_plasma0)); // R0a


	/* Stage 3
			C0= $plasma_color
			C1= $plasma_flash_color

			R0a= OUTPUT_SCALE_BY_4(R0b*R0b mux R0a*R0a)
			V1= UNSIGNED_INVERT(C0a)*C0 + C0*C1

			If R0a is greater than than 0.5, CD is returned, else AB
	*/
			float3 color = lerp(plasma_color.rgb, plasma_flash_color, plasma_color.a); // V1
			float plasma = plasma_intermed1 < 0.5 ? pow(plasma_intermed1, 2.0) : pow(plasma_intermed0, 2.0); // R0a
				plasma = plasma*4.0;

	/* Stage 4
			C0a=	$plasma_factor3

			T3=		T3*C0a
			R0a= 	OUT_SCALE_BY_4(0 mux EXPAND(R0a)*EXPAND(R0a))
	*/
				T3 *= plasma_factor3;
			float plasma_sharp = plasma < 0.5 ? 0 : pow(EXPAND(plasma), 2.0); // R0a

	/* Stage 5
			R1= 	INVERT(T3a)
			R0a= 	OUT_SCALE_BY_ONE_AND_ONE_HALF(R0a + R0a*INVERT(R0a))
	*/

			float plasma_dull = plasma_sharp + plasma_sharp*INVERT(plasma_sharp); // R0a

	/* Stage 6
			R0= 	R0*T3 + V1*R1

			SRCCOLOR= 	R0 * $plasma_brightness
			SRCALPHA=	R0a
	*/
			albedo.rgb = plasma_dull*T3 + color*INVERT(T3a); // R0
			albedo.a = plasma_dull; // R0a


	//apply_pc_albedo_modifier(albedo, normal);

}

PARAM(float3, plasma_tint);
PARAM(float3, glow);

void calc_albedo_plasma_offset_new_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 T2 = 				sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform)).a;
	float T1 = 					sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform)).a;
	float T0 = 					sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform)).a;

	/* Only the following parameters are used */
	
	float3 T3 = plasma_mask.rgb;
	float T3a = plasma_mask.a;


	// This is Halo 2's Implementation, the difference being the plasma mask's RGB can now be tinted

	/* Stage 0
	C0 = (0, 0, $plasma_factor2)
	C0a = $plasma_factor1

	R0= 	INVERT(C0a)*T2a + C0a*T0a
	R0a= 	INVERT(C0b)*1/2 + C0b*T1a
	*/
			float pre_plasma0 = lerp(T2, T0, plasma_factor1); // R0
			float pre_plasma1 = lerp(0.5, T1, plasma_factor2); // R0a

	/* Stage 1
	R0= 	T3*1/2 + INVERT(T3a)*R0
	R0a= 	T3a*1/2 + INVERT(T3a)*R0a
	*/
			float masked_plasma0 = T3a*0.5 + INVERT(T3a)*pre_plasma0 ; //R0
			float masked_plasma1 =  T3a*0.5 + INVERT(T3a)*pre_plasma1 ; // R0a

	/* Stage 2
	R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
	R0a= 	R0a + HALF_BIAS_NEGATIVE(R0b)
	*/

			float plasma_intermed0 = (masked_plasma0 + HALF_BIAS_NEGATIVE(masked_plasma1)); // R0
			float plasma_intermed1 = (masked_plasma1 + HALF_BIAS_NEGATIVE(masked_plasma0)); // R0a


	/* Stage 3
			C0a= $plasma_factor3

			T3=	T3*C0a
			R0a= SCALE_BY_4(R0b*R0b mux R0a*R0a)

			If R0a is greater than than 0.5, CD is returned, else AB
	*/
			T3=			(T3*plasma_factor3);				// mask strength

			float plasma = plasma_intermed1 < 0.5 ? pow(plasma_intermed1, 2.0) : pow(plasma_intermed0, 2.0); // R0a
				plasma = plasma*4.0;



	/* Stage 4
	C0= 	$plasma_tint
	T3= 	T3*C0

	R0a= 	0 mux EXPAND_UNSIGNED(R0a)*EXPAND_UNSIGNED(R0a)
	*/
			T3= 		plasma_tint*T3;
			float plasma_sharp = plasma < 0.5 ? 0 : pow(EXPAND(plasma), 2.0); // R0a

	/* Stage 5
	C1= 	$glow

	R1= 	INVERT(T3a)
	R0= 	INVERT(T3a)*C1
	R0a= 	OUT_SCALE_BY_2(UNSIGNED(R0a) + UNSIGNED(R0a)*UNSIGNED_INVERT(R0a))
	*/
			float3 plasma_colorized= INVERT(T3a)*glow;
			float plasma_dull = plasma_sharp + plasma_sharp*INVERT(plasma_sharp); // R0a
			
	/* Stage 6
	R0= 	UNSIGNED(R0a)*T3 + R0
	R0= 	R0 * $plasma_brightness
	*/
			albedo.rgb= 	plasma_dull*T3 + plasma_colorized;
			albedo.rgb*= 	plasma_brightness;
			albedo.a = plasma_dull; // R0a


	//apply_pc_albedo_modifier(albedo, normal);
}

PARAM(bool, dot_mask);

void calc_albedo_plasma_offset_masked_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 T2 = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform)).a;
	float4 T1 = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform)).a;
	float4 T0 = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform)).a;

	// This is Halo another version of 1's Implementation the difference is the last stage is that
	//	the plasma flash color is multiplied to the mask's rgb components

		/* Only the following parameters are used */
		
		float3 T3 = plasma_mask.rgb;
		float T3a = plasma_mask.a;		
	/* Stage 0
	C0 = (0, 0, $plasma_factor2)
	C0a = $plasma_factor1

	R0= 	INVERT(C0a)*T2a + C0a*T0a
	R0a= 	INVERT(C0b)*1/2 + C0b*T1a
	*/
			float pre_plasma0 = lerp(T2, T0, plasma_factor1); // R0
			float pre_plasma1 = lerp(0.5, T1, plasma_factor2); // R0a

	/* Stage 1
	R0= 	T3*1/2 + INVERT(T3a)*R0
	R0a= 	T3a*1/2 + INVERT(T3a)*R0a
	*/
			float masked_plasma0 = T3a*0.5 + INVERT(T3a)*pre_plasma0 ; //R0
			float masked_plasma1 =  T3a*0.5 + INVERT(T3a)*pre_plasma1 ; // R0a

	/* Stage 2
	R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
	R0a= 	R0a + HALF_BIAS_NEGATIVE(R0b)
	*/

			float plasma_intermed0 = (masked_plasma0 + HALF_BIAS_NEGATIVE(masked_plasma1)); // R0
			float plasma_intermed1 = (masked_plasma1 + HALF_BIAS_NEGATIVE(masked_plasma0)); // R0a


	/* Stage 3
			C0= $plasma_color
			C1= $plasma_flash_color

			R0a= OUTPUT_SCALE_BY_4(R0b*R0b mux R0a*R0a)
			V1= UNSIGNED_INVERT(C0a)*C0 + C0*C1

			If R0a is greater than than 0.5, CD is returned, else AB
	*/
			float3 color = lerp(plasma_color.rgb, plasma_flash_color, plasma_color.a); // V1
			float plasma = plasma_intermed1 < 0.5 ? pow(plasma_intermed1, 2.0) : pow(plasma_intermed0, 2.0); // R0a
				plasma = saturate(plasma*4.0);

	/* Stage 4
			C0a=	$plasma_factor3

			T3=		T3*C0a
			R0a= 	OUT_SCALE_BY_4(0 mux EXPAND(R0a)*EXPAND(R0a))
	*/
			float dot_mask_t3 = dot(T3, 1)*plasma_factor3;
				
				T3 *= plasma_factor3;
			float plasma_sharp = plasma < 0.5 ? 0 : pow(EXPAND(plasma), 2.0); // R0a

	/* Stage 5
			R1= 	INVERT(T3a)
			R0a= 	OUT_SCALE_BY_ONE_AND_ONE_HALF(R0a + R0a*INVERT(R0a))
	*/

			float plasma_dull = plasma_sharp + plasma_sharp*INVERT(plasma_sharp); // R0a

	/* Stage 6
			R0= 	R0*T3 + V1*R1

			SRCCOLOR= 	R0 * $plasma_brightness
			SRCALPHA=	R0a
	*/
			albedo.rgb = dot_mask ? (plasma_dull*T3) + (color*dot_mask_t3) : (plasma_dull*T3) + (color*T3); // R0
			albedo.a = plasma_dull; // R0a


	//apply_pc_albedo_modifier(albedo, normal);


}

void calc_albedo_plasma_offset_inverse_mask_alpha_ps(
	in float2 texcoord,
	out float4 albedo,
    in float3 normal,
	/*in float4 view_dir,*/
	in float4 misc)
{
	float4 plasma_mask = 		sample2D(plasma_mask_map, transform_texcoord(texcoord, plasma_mask_map_xform));
	float4 plasma_offset = 		sample2D(plasma_offset_map, transform_texcoord(texcoord, plasma_offset_map_xform));
	float4 plasma_noise_b = 	sample2D(plasma_noise_map_b, transform_texcoord(texcoord, plasma_noise_map_b_xform));
	float4 plasma_noise_a = 	sample2D(plasma_noise_map_a, transform_texcoord(texcoord, plasma_noise_map_a_xform));

	// This is Halo another version of 1's Implementation the difference is the last stage is that
	//	the plasma flash color is multiplied to the mask's rgb components

		/* Only the following parameters are used */
		
		float3 T3 = plasma_mask.rgb;
		float T3a = plasma_mask.a;
		float T2 = 	plasma_offset.a;
		float T1 = 	plasma_noise_b.a;
		float T0 = 	plasma_noise_a.a;
		
		float4 	R0;
		float4 	R1;
		float4  V1;

		//float view_dot_normal = normalize(dot(view_dir.xyz, normal));
		float3	a, b, c, d, ab, cd, ab_cd;
		float	a_a, b_a, c_a, d_a, ab_a, cd_a, ab_cd_a;


	/* Stage 0
	C0 = (0, 0, $plasma_factor2)
	C0a = $plasma_factor1

	R0= 	INVERT(C0a)* UNSIGNED(T2a) + C0a*UNSIGNED(T0r)
	R0a= 	INVERT(C0b)*1/2 + C0a*UNSIGNED(T1r)
	*/
			R0.rgb= 	saturate_h1( saturate_h1(UNSIGNED_INVERT(plasma_factor1)*UNSIGNED(T2)) + saturate_h1(UNSIGNED(plasma_factor1)*UNSIGNED(T0)) );
			R0.a= 		saturate_h1( saturate_h1(UNSIGNED_INVERT(plasma_factor2)*UNSIGNED(0.5)) + saturate_h1(UNSIGNED(plasma_factor2)*UNSIGNED(T1)) );



	/* Stage 1
	R0= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0
	R0a= 	UNSIGNED(T3a)*1/2 + INVERT(T3a)*R0a
	*/
			R0.a= 		saturate_h1( saturate_h1(saturate_h1(UNSIGNED(T3a)*UNSIGNED(0.5)) + saturate_h1(UNSIGNED_INVERT(T3a)*UNSIGNED(R0.a))) );
			R0.rgb= 	saturate_h1( saturate_h1(saturate_h1(UNSIGNED(T3a)*UNSIGNED(0.5)) + saturate_h1(UNSIGNED_INVERT(T3a)*UNSIGNED(R0.rgb))) );

	/* Stage 2
	R0= 	R0 + HALF_BIAS_NEGATIVE(R0a)
	R0a= 	UNSIGNED(R0a) + HALF_BIAS_NEGATIVE(R0b)
	*/
			R0.a= 		saturate_h1(saturate_h1(UNSIGNED(R0.a)) + saturate_h1(HALF_BIAS_UNSIGNED_NEGATIVE(R0.b)));

			R0.rgb= 	saturate_h1(saturate_h1(UNSIGNED(R0.rgb)) + saturate_h1(HALF_BIAS_UNSIGNED_NEGATIVE(R0.a)));

	/* Stage 3
			C0= $plasma_color
			C1= $plasma_flash_color

			R0a= SCALE_BY_4(R0b*R0b mux R0a*R0a)
			V1= UNSIGNED_INVERT(C0a) * C0 + C0 * C1

			If R0a is greater than than 0.5, CD is returned, else AB
	*/
			R0.a= 		R0.a < 0.5 ? saturate_h1(pow(R0.a, 2.0)) : saturate_h1(pow(R0.b, 2.0));
			R0.a= 		4.0 * saturate_h1(R0.a);

			V1.rgb= 	INVERT(plasma_color.a)*plasma_color.rgb + plasma_color.a*plasma_flash_color; //C0a's value determines what color the shield is


	/* Stage 4
	R0a= 	OUTPUT_SCALE_BY_1_AND_ONE_HALF(0 mux EXPAND_UNSIGNED(R0a)*EXPAND_UNSIGNED(R0a))
	*/
			R0.a = 		R0.a < 0.5 ? saturate_h1(0) : saturate_h1(pow(EXPAND_UNSIGNED(R0.a), 2.0));
			R0.a = 		1.5*saturate_h1(R0.a);


	/* Stage 5
	R1= 	INVERT(T3a)
	R0a= 	OUT_SCALE_BY_2(UNSIGNED(R0a) + UNSIGNED(R0a)*UNSIGNED_INVERT(R0a))
	*/
			//R1.rgb= 	INVERT(T3a);
			R0.a= 		saturate_h1(saturate_h1(UNSIGNED(R0.a)) + saturate_h1(UNSIGNED(R0.a)*UNSIGNED_INVERT(R0.a)));
			R0.a*=		1.5;

	/* Stage 6
	R0= 	UNSIGNED(R0a)*T3 + V1*R1
	R0= 	R0 * $plasma_brightness
	*/
			R0.rgb=		saturate_h1(saturate_h1(UNSIGNED(R0.a)*UNSIGNED(T3)) + saturate_h1(UNSIGNED(V1.rgb)*UNSIGNED(T3)));
			R0.rgb*= 	plasma_brightness;

	albedo = 	R0;

	//apply_pc_albedo_modifier(albedo, normal);
}


#endif

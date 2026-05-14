#version 330

in  vec2 otexcoord;
out vec4 frag_color;

uniform	vec2           uterm_size;
uniform ivec2          usheet_size;
uniform	int            usheet_offset;
uniform	int            uline_space;
uniform sampler2D      udiffuse;
uniform usamplerBuffer udata;

void main(void)
{
	if ( otexcoord.x > 1.0 || otexcoord.y > 1.0 )
		discard;
	vec2 coord   = otexcoord * uterm_size;
	coord.y      = uterm_size.y - coord.y;
	ivec2 ts     = textureSize( udiffuse, 0 );
	int  lines   = ts.y / usheet_size.y;
	float lfac   = float( uline_space ) / float( lines );
	vec2 tc      = fract( coord ) * vec2( 1.0, 1.0 + lfac ) - vec2( 0.0, lfac * 0.5 );

	int index = int( coord.x ) + int( uterm_size.x ) * int( coord.y );
	uvec4 data_sample = texelFetch( udata, index ).rgba;

	uint fg   = data_sample.r;//.fg;
	uint bg   = data_sample.g;//.bg;

	int glyph = int( data_sample.b ) - usheet_offset;//.glyph
	ivec2 gxy = ivec2( glyph % usheet_size.x, glyph / usheet_size.x );
	vec2 gpos = vec2( ( float( gxy.x ) + tc.x ) / float( usheet_size.x ), ( float( gxy.y ) + tc.y ) / float( usheet_size.y ) );
	vec4 tt   = texelFetch( udiffuse, ivec2( gpos * vec2( ts ) ), 0 );
	if ( tc.y < 0 || tc.y > 1.0 )
		tt.x = 0;
	
    vec4 fg_color = vec4(
		float( ( fg & uint(0xFF000000) ) >> 24 ) / 255.0,
        float( ( fg & uint(0x00FF0000) ) >> 16 ) / 255.0,
        float( ( fg & uint(0x0000FF00) ) >> 8 ) / 255.0,
        float( ( fg & uint(0x0000000F) ) ) / 16.0
	);
    vec4 bg_color = vec4(
		float( ( bg & uint(0xFF000000) ) >> 24 ) / 255.0,
        float( ( bg & uint(0x00FF0000) ) >> 16 ) / 255.0,
        float( ( bg & uint(0x0000FF00) ) >> 8 ) / 255.0,
        float(   bg & uint(0x000000FF) ) / 16.0
	);
	vec3 out_fg = fg_color.xyz * tt.x;
	vec3 out_bg = bg_color.xyz * ( 1.0f - tt.x );
	float fg_a  = fg_color.w * tt.x;
	float bg_a  = bg_color.w * ( 1.0f - tt.x );
	frag_color = vec4( out_fg + out_bg, fg_a + bg_a );
}

shader_type canvas_item;

uniform float glow;
uniform sampler2D curve;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

vec3 rgb2hsb( in vec3 c ){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                d / (q.x + e),
                q.x);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float doubleCubicSeat (float x, float a, float b){

  float epsilon = 0.00001;
  float min_param_a = 0.0 + epsilon;
  float max_param_a = 1.0 - epsilon;
  float min_param_b = 0.0;
  float max_param_b = 1.0;
  a = min(max_param_a, max(min_param_a, a));
  b = min(max_param_b, max(min_param_b, b));

  float y = 0.0;
  if (x <= a){
    y = b - b*pow(1.0-x/a, 3.0);
  } else {
    y = b + (1.0-b)*pow((x-a)/(1.0-a), 3.0);
  }
  return y;
}

float mix2(float edge, float mid, float t) {
	return mix(mix(0.0, mid, t/edge), mix(mid, 1.0, (t-edge)/(1.0-edge)), step(edge, t));
}

void fragment() {
	vec4 back = textureLod(screen_texture, SCREEN_UV, 0.0);

	vec2 st = vec2(0.5f, 0.5f);
	vec3 col =  back.rgb;
	float alpha = back.a;
	col = rgb2hsb(col);
	 //t is distance to rectangle
	float t = min(min(UV.x, 1.0-UV.x), min(UV.y, 1.0-UV.y));
	t = texture(curve, vec2(t, 0.5)).r;
	col.y = mix(col.y, 0.0, t);
	col.z = mix(col.z, 1.0, t);
	col = hsb2rgb(col);
	COLOR = mix(back, vec4(col, alpha), glow);
	//COLOR = texture(TEXTURE, UV);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}

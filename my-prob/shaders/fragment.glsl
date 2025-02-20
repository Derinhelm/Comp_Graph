#version 330

#define float2 vec2
#define float3 vec3
#define float4 vec4
#define float4x4 mat4
#define float3x3 mat3

in float2 fragmentTexCoord;

layout(location = 0) out vec4 fragColor;

uniform int g_screenWidth;
uniform int g_screenHeight;

uniform float3 g_bBoxMin   = float3(-1,-1,-1);
uniform float3 g_bBoxMax   = float3(+1,+1,+1);

uniform float4x4 g_rayMatrix;

uniform float4   g_bgColor = float4(0,0,1,1);

float3 EyeRayDir(float x, float y, float w, float h)
{
	float fov = 3.141592654f/(2.0f); 
  float3 ray_dir;
  
	ray_dir.x = x+0.5f - (w/2.0f);
	ray_dir.y = y+0.5f - (h/2.0f);
	ray_dir.z = -(w)/tan(fov/2.0f);
	
  return normalize(ray_dir);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

int RayIntersection(vec3 ray_pos, vec3 ray_dir){
    int max_steps = 64;
    float mindist = 0.01f;
    for (int i = 0; i < max_steps; i++) {
        float dist1 = sdSphere(ray_pos - vec3(1.0f, 1.0f, 1.0f), 0.7f);
        float dist2 = sdBox(ray_pos - vec3(-1.0f, -1.0f, -1.0f), vec3(0.5, 0.5, 0.5));
        float dist = min(dist1, dist2);
        if (abs(dist) < mindist) {
            if (dist1 < dist2) {
                return 1;
            } else {
                return 2;
            }
        }
        if (abs(dist) < 0.01f) {
            if (dist < 0) {
                dist = -0.01f;
            } else {
                dist = 0.01f;  
            }
        } 
        ray_pos = ray_pos + ray_dir * dist;
    }
    return 0;
}

void main(void)
{	

  float w = float(g_screenWidth);
  float h = float(g_screenHeight);
  
  // get curr pixelcoordinates
  //
  float x = fragmentTexCoord.x*w; 
  float y = fragmentTexCoord.y*h;
  
  // generate initial ray
  //
  float3 ray_pos = float3(0,0,0); 
  float3 ray_dir = EyeRayDir(x,y,w,h);
 
  // transorm ray with matrix
  //
  ray_pos = (g_rayMatrix*float4(ray_pos,1)).xyz;
  ray_dir = float3x3(g_rayMatrix)*ray_dir;
  switch (RayIntersection(ray_pos, ray_dir)) {
      case 2:
          fragColor = float4(0.5, 1.0, 1.0, 1.0); 
          break;
      case 1:
          fragColor = float4(0.0f, 1.0f, 0.0f, 1.0);
          break;
      case 0:
          fragColor = float4(1.0f, 0.0f, 0.0f, 1.0); 
          break;

  }

}



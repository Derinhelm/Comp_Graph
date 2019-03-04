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
uniform float3 light = float3(1.5f, 1.5f, 1.5f);
uniform float3 lightColor = float3(1.0f, 1.0f, 1.0f);

uniform float3 g_camPos = float3(0, 0, 5);

uniform float mindist = 0.001f;

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



float RayIntersection(vec3 ray_pos, vec3 ray_dir){
    int max_steps = 64;
    float alldist = 0.0f;
    for (int i = 0; i < max_steps; i++) {
        float dist = sdSphere(ray_pos, 1.0f);
        
        if (dist < mindist) {
            return alldist; 
        } 
        if (abs(dist) < 0.001f) {
            dist = (dist > 0)?0.001f:-0.001f;
        }
        ray_pos = ray_pos + ray_dir * dist;
        alldist += dist;
    }
    return -1.0f;
}
float DistanceEvaluation(float3 v)
{
   return sdSphere(v, 1.0f);
}

float3 EstimateNormal(float3 z, float eps)
{
    float3 z1 = z + float3(eps, 0, 0);
    float3 z2 = z - float3(eps, 0, 0);
    float3 z3 = z + float3(0, eps, 0);
    float3 z4 = z - float3(0, eps, 0);
    float3 z5 = z + float3(0, 0, eps);
    float3 z6 = z - float3(0, 0, eps);
    float dx = DistanceEvaluation(z1) - DistanceEvaluation(z2);
    float dy = DistanceEvaluation(z3) - DistanceEvaluation(z4);
    float dz = DistanceEvaluation(z5) - DistanceEvaluation(z6);
    return normalize(float3(dx, dy, dz) / (2.0*eps));
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
  float3 light[2];
    light[0] = float3(1.5f, 1.5f, 1.5f);
    light[1] = float3(1.5f, 1.5f, 0.0f);;
    float3 lightColor = float3(1.0f, 1.0f, 1.0f);


    float intersect = RayIntersection(ray_pos, ray_dir);
    float3 norm, result, point_pos, objectColor;
    float3 ItogColor = float3(0.0f, 0.0f, 0.0f);
    if (intersect ==  -1.0f) {
        fragColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
    } else {
        objectColor = float3(0.0, 1.0, 0.0);
        point_pos = ray_pos + ray_dir * intersect;
        norm = normalize(EstimateNormal(point_pos, 0.01f));
        
        for (int j = 0; j < 2; j++) {
            float3 cur_light = light[j];
            
            float ambientStrength = 0.15f;
            float3 ambient = ambientStrength * lightColor;     
            float3 lightDir = normalize(cur_light - point_pos);
            if (length((cur_light + RayIntersection(cur_light, -lightDir) * (-lightDir)) - point_pos) > 0.1f) {
                result = ambient * objectColor; //shadow
            } else {
                float diff = max(dot(norm, lightDir), 0.0);
                float3 diffuse = diff * lightColor;

                float specularStrength = 0.5f;
                float3 viewDir = normalize(g_camPos - point_pos);
                float3 reflectDir = reflect(-lightDir, norm);
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), 64);
                float3 specular = specularStrength * spec * lightColor;
  
                result = (ambient + diffuse + specular) * objectColor;
            }
            ItogColor += result;
        }

        fragColor = float4(ItogColor, 1.0f);
    }

}


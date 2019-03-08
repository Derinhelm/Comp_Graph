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
uniform int number_task;
uniform int move1;
uniform int move2;

uniform float3 g_bBoxMin   = float3(-1,-1,-1);
uniform float3 g_bBoxMax   = float3(+1,+1,+1);

uniform float4x4 g_rayMatrix;

uniform float4   g_bgColor = float4(0,0,1,1);


uniform float3 g_camPos = float3(0, 0, 5);

uniform float mindist = 0.001f;
uniform float my_t;

uniform float3 plane_norm = normalize(vec3(0.0f, 1.0f, 0.0f));
uniform float2 vec_tor = vec2(1.1f, 0.1f);
uniform float3 vec_cyl = float3(0.0,0.0,0.1);
uniform vec2 vec_cone = normalize(vec2(1.5f, 1.0f));

uniform mat4 mTor = mat4(
    1, 0, 0, 0,
    0, 0.86602540378, 0.5, 0,
    0, -0.5, 0.86602540378, 0,
    0, 0, 0, 1);
uniform mat4 mCone = mat4(
    1, 0, 0, 0,
    0, 0, -1, 0,
    0, 1, 0, 0,
    0, 0, 0, 1);
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

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
    return dot(p,n.xyz) + n.w;
}



float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}
float turnTor( vec3 p)
{
    mat4 inv = inverse(mTor);
    vec3 q = (inv*vec4(p, 1.0)).xyz;
    return sdTorus(q, vec_tor);
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float turnCone( vec3 p)
{
    mat4 inv = inverse(mCone);
    vec3 q = (inv*vec4(p, 1.0)).xyz;
    return sdCone(q, vec_cone);
}

float RayIntersection(vec3 ray_pos, vec3 ray_dir, int number_figure){
    int max_steps = 64;
    float alldist = 0.0f;
    float dist;
    for (int i = 0; i < max_steps; i++) {
        switch (number_figure) {
            case 1:
                if (move2 == 1) {
                    float x = cos(2 * my_t) * 0.5;
                    float z = sin(2 * my_t) * 0.5;
                    dist = sdSphere(ray_pos - float3(x, 1.05, z), 0.2f);
                } else {
                    dist = sdSphere(ray_pos - float3(0.5, 1.05, 0.5), 0.2f);
                }
                break;
            case 2:
                dist = sdPlane(ray_pos, vec4(plane_norm, 1.0f));
                break;
            case 3:
                if (move1 == 1) {
                    float t = (sin(my_t) / 2 + 0.5) * 2;
                    dist = turnTor(ray_pos - vec3(0.0f, t, 0.0f));
                } else {
                    dist = turnTor(ray_pos - vec3(0.0f, 1.0f, 0.0f));
                }
                break;
            case 4:
                dist = sdCylinder(ray_pos, vec_cyl);
                break;
            case 5:
                dist = turnCone(ray_pos);
                break;

        }
                
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

float2 ManyRayIntersection(vec3 ray_pos, vec3 ray_dir) { // rez.x - расстояние, rez.y - с какой фигурой пересеклись
    float d = RayIntersection(ray_pos, ray_dir, 1);
    float2 rez;
    rez.x = d;
    rez.y = 1;
    for (int i = 2; i < 6; i++) {
        float new_dist = RayIntersection(ray_pos, ray_dir, i);
        if (new_dist != -1.0f) {
            if (rez.x == -1.0f || rez.x > new_dist) {
                rez.xy = float2(new_dist, i);
            }
        }
    }
    return rez;
}
float DistanceEvaluation(float3 v, int number_figure)
{
    switch (number_figure) {
        case 1:
            return sdSphere(v, 1.0f);
        case 2:
            return sdPlane(v, vec4(plane_norm, 1.0f));
        case 3:
            return turnTor(v);
        case 4:
            return sdCylinder(v, vec_cyl);
        case 5:
            return turnCone(v);
    }
}


float3 EstimateNormal(float3 z, float eps, int number_figure)
{
    float3 z1 = z + float3(eps, 0, 0);
    float3 z2 = z - float3(eps, 0, 0);
    float3 z3 = z + float3(0, eps, 0);
    float3 z4 = z - float3(0, eps, 0);
    float3 z5 = z + float3(0, 0, eps);
    float3 z6 = z - float3(0, 0, eps);
    float dx = DistanceEvaluation(z1, number_figure) - DistanceEvaluation(z2, number_figure);
    float dy = DistanceEvaluation(z3, number_figure) - DistanceEvaluation(z4, number_figure);
    float dz = DistanceEvaluation(z5, number_figure) - DistanceEvaluation(z6, number_figure);
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
    light[0] = float3(0.5f, 1.8f, 0.5f);
    light[1] = float3(0.7f, 1.0f, 0.3f);
    float3 lightColor = float3(1.0f, 1.0f, 1.0f);


    float2 intersect = ManyRayIntersection(ray_pos, ray_dir);
    float3 norm, result, point_pos, objectColor;
    float3 ItogColor = float3(0.0f, 0.0f, 0.0f);
    float3 ambientStrength, diffuseStrength, specularStrength;
    if (intersect.x ==  -1.0f) {
        fragColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
    } else {
        switch (int(intersect.y)) {
            case 1:
                objectColor = float3(0.0, 1.0, 0.0);
                point_pos = ray_pos + ray_dir * intersect.x;
                norm = normalize(EstimateNormal(point_pos, 0.01f, 1));
                ambientStrength = float3(0.0215, 0.1745, 0.0215);
                diffuseStrength = float3(0.07568, 0.61424, 0.07568);
                specularStrength = float3(0.633, 0.727811,	0.633);
                break;
            case 2:
                objectColor = float3(1.0, 0.0, 0.0);
                point_pos = ray_pos + ray_dir * intersect.x;
                norm = normalize(EstimateNormal(point_pos, 0.01f, 2));
                ambientStrength = float3(0.1745, 0.01175, 0.01175);
                diffuseStrength = float3(0.61424, 0.04136, 0.04136);
                specularStrength = float3(0.727811, 0.626959, 0.626959);
                break;
            case 3:
                objectColor = float3(0.86, 0.90, 0.92);
                point_pos = ray_pos + ray_dir * intersect.x;
                norm = normalize(EstimateNormal(point_pos, 0.01f, 3));
                ambientStrength = float3(0.25, 0.25, 0.25);
                diffuseStrength = float3(0.4, 0.4, 0.4);
                specularStrength = float3(0.774597, 0.774597, 0.774597);
                break;
            case 4:
                objectColor = float3(0.0, 1.0, 1.0);
                point_pos = ray_pos + ray_dir * intersect.x;
                norm = normalize(EstimateNormal(point_pos, 0.01f, 4));
                ambientStrength = float3( 0.1,0.18725, 0.1745);
                diffuseStrength = float3(0.396, 0.74151, 0.69102);
                specularStrength = float3(0.297254, 0.30829, 0.306678);
                break;
            case 5:
                objectColor = float3(1.0, 0.8, 0.0);
                point_pos = ray_pos + ray_dir * intersect.x;
                norm = normalize(EstimateNormal(point_pos, 0.01f, 5));
                ambientStrength = float3(0.24725, 0.1995, 0.0745);
                diffuseStrength = float3(0.75164, 0.60648, 0.22648);
                specularStrength = float3(0.628281, 0.555802, 0.366065);
                break;
        }

        for (int j = 0; j < 3; j++) {
            float3 cur_light = light[j];
            
            float3 ambient = ambientStrength * lightColor;     
            float3 lightDir = normalize(cur_light - point_pos);
            if (number_task == 1 && length((cur_light + ManyRayIntersection(cur_light, -lightDir).x * (-lightDir)) - point_pos) > 0.1f) {
                result = ambient * objectColor; //shadow
            } else {
                float diff = max(dot(norm, lightDir), 0.0);
                float3 diffuse = diffuseStrength * diff * lightColor;

                float3 viewDir = normalize(g_camPos - point_pos);
                float3 reflectDir = reflect(-lightDir, norm);
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), 128);
                float3 specular = specularStrength * spec * lightColor;
  
                result = (ambient + diffuse + specular) * objectColor;
            }
            ItogColor += 0.5 * result;
        }

 
        fragColor = float4(ItogColor, 1.0f);
    }
    

}
#version 330

// Input vertex attributes (from vertex shader)
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here
#define     MAX_LIGHTS              16
#define     LIGHT_DIRECTIONAL       0
#define     LIGHT_POINT             1

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
};

// Input lighting values
uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;

void main()
{
		bool lit = false;

    for (int i = 0; i < MAX_LIGHTS; i++)
    {
        if (lights[i].enabled == 1)
        {
					float lightDistance = distance(fragPosition, lights[i].position);
					if (lightDistance <= 14)
					{
						lit = true;
					}
        }
    }

		if (lit)
		{
			finalColor = fragColor;
		} else {
			finalColor = ambient;
		}
		//finalColor = fragColor;

    //finalColor = (texelColor*((tint + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
    //finalColor += texelColor*(ambient/10.0)*tint;
		//finalColor = vec4(lights[0].position.x / 25.0, lights[0].position.y / 25.0, 0.0, 1.0);


    // Gamma correction
    //finalColor = pow(finalColor, vec4(1.0/2.2));

		// Banded lighting
		//float lightDist = 1.0 / distance(fragPosition, lights[0].position);
		//finalColor = mix(vec4(0.0,0.0,0.0,1.0), texelColor*(ambient*5.0), lightDist);
}

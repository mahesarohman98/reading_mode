#!/bin/sh

MODE="normal"
GRAYSCALE=1

# Regular expression for numbers between 0 and 1 (inclusive)
DECIMAL_PATTERN='^[0-1]?\.[0-9]+$|^0$|^1$'

# Parse command-line arguments
for arg in "$@"; do
    if [ "$arg" = "reading" ]; then
        MODE="reading"
    elif [ "$arg" = "normal" ]; then
        MODE="normal"
    elif echo "$arg" | grep -Eq "$DECIMAL_PATTERN"; then
        GRAYSCALE=$arg
    else
        echo "Invalid argument: $arg"
        exit 1
    fi
done

# Define the shader with dynamic desaturation based on GRAYSCALE
SHADER=$(cat <<-END
#version 330

in vec2 texcoord;
uniform sampler2D tex;
float desaturation_factor = $GRAYSCALE; // Adjust for your desired level of desaturation

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    vec2 texsize = textureSize(tex, 0);
    vec4 color = texture2D(tex, texcoord / texsize, 0);

    // Apply a slight desaturation
    float gray = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;

    // Mix the color with grayscale based on the desaturation factor
    color.rgb = mix(color.rgb, vec3(gray), desaturation_factor);

    return default_post_processing(color);
}
END
)

# Create the shader file
echo "$SHADER" > /tmp/shader.glsl

# Kill any existing Picom processes to reset
killall picom
redshift -P -o  ;  # Ensure the default Redshift settings are applied
if [ "$MODE" = "normal" ]; then
    picom --backend glx -b  # Start Picom with default settings
else
    # In "reading" mode, adjust Redshift settings to a softer tone
    redshift -O 4500 -g 0.97:0.93:0.90
    picom --backend glx --config ~/.config/picom/picom.conf --window-shader-fg /tmp/shader.glsl -b
fi



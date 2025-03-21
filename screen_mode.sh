#!/bin/sh

MODE="normal"
BRIGHTNESS=1
GRAYSCALE=1
REDSHIFT=5500
ARGKEY=""

# Regular expression for numbers between 0 and 1 (inclusive)
# Regular expressions
DECIMAL_PATTERN='^0(\.[0-9]+)?$|^1(\.0+)?$'  # 0 to 1 (e.g., 0.4, 1, 0.99)
NUMBER_PATTERN='^[0-9]+$'                    # Whole numbers (e.g., 4500)

# Help message
print_help() {
    cat <<EOF
Usage: $(basename "$0") [mode] [-d GRAYSCALE] [-t REDSHIFT]

Modes:
  reading           Set mode to reading
  normal            Set mode to normal (default)

Options:
  -b BRIGHTNESS     Brightness value between o and 1 (default: 1)
  -d GRAYSCALE      Grayscale value between 0 and 1 (default: 1)
  -t REDSHIFT       Redshift value as a number (default: 5500)
  -h, --help        Show this help message

Examples:
  $(basename "$0") reading -d 0.5 -t 4500
  $(basename "$0") normal
EOF
}

# Parse command-line arguments
for arg in "$@"; do
    if [ "$ARGKEY" = "BRIGHTNESS" ]; then
        if echo "$arg" | grep -Eq "$DECIMAL_PATTERN"; then
            BRIGHTNESS=$arg
        else
            echo "Invalid Brightness value: $arg. Must be between 0 and 1."
            exit 1
        fi
        ARGKEY=""  # Reset ARGKEY
        continue
    fi
    if [ "$ARGKEY" = "GRAYSCALE" ]; then
        if echo "$arg" | grep -Eq "$DECIMAL_PATTERN"; then
            GRAYSCALE=$arg
        else
            echo "Invalid grayscale value: $arg. Must be between 0 and 1."
            exit 1
        fi
        ARGKEY=""  # Reset ARGKEY
        continue
    fi

    if [ "$ARGKEY" = "REDSHIFT" ]; then
        if echo "$arg" | grep -Eq "$NUMBER_PATTERN"; then
            REDSHIFT=$arg
        else
            echo "Invalid redshift value: $arg. Must be a number."
            exit 1
        fi
        ARGKEY=""  # Reset ARGKEY
        continue
    fi

    case "$arg" in
        reading) MODE="reading" ;;
        normal) MODE="normal" ;;
        -b) ARGKEY="BRIGHTNESS" ;;
        -d) ARGKEY="GRAYSCALE" ;;
        -t) ARGKEY="REDSHIFT" ;;
        *) echo "Invalid argument: $arg"; print_help; exit 1 ;;
    esac
done

# Define the shader with dynamic desaturation based on GRAYSCALE
SHADER=$(cat <<-END
#version 330

in vec2 texcoord;
uniform sampler2D tex;
float desaturation_factor = $GRAYSCALE; // Adjust for your desired level of desaturation
float natural_tone_factor = 0.1;

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    vec2 texsize = textureSize(tex, 0);
    vec4 color = texture2D(tex, texcoord / texsize, 0);

    float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 desaturated_color = mix(color.rgb, vec3(gray), -1*desaturation_factor);

    vec3 natural_tone = mix(desaturated_color, vec3(0.95, 0.92, 0.88), natural_tone_factor);

    float final_gray = dot(natural_tone, vec3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(natural_tone, vec3(final_gray), desaturation_factor);

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
    redshift -O -b "$BRIGHTNESS"
    picom --backend glx --config ~/.config/picom/picom.conf  -b # Start Picom with default settings
else
    # In "reading" mode, adjust Redshift settings to a softer tone
    # redshift -O "$REDSHIFT" -g 0.85:0.85:0.80 -b "$BRIGHTNESS"
    redshift -O "$REDSHIFT" -b 1  # Ensure the default Redshift settings are applied
    picom --backend glx --config ~/.config/picom/picom.conf --window-shader-fg /tmp/shader.glsl -b
fi



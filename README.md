# Screen Mode

This script allows you to switch between Normal Mode and Reading Mode, with adjustable desaturation for better eye comfort.

## Dependency

Ensure you have the following installed before using the script:
- picom (for applying the shader effect)
- redshift (for adjusting screen color temperature)

## Usage

### Normal Mode
- Runs the screen in its default state.
	```sh
	    ./screen_mode.sh normal
	```

### Reading Mode 

Reading mode applies a softer, paper-like display effect with adjustable desaturation.

- Partial desaturation (OnePlus Chromatic-like effect):
	```sh
    ./screen_mode.sh reading 0.6
	```
	*A balance between color and grayscale, reducing eye strain while keeping some color visibility.*

- Full desaturation (Monochrome/Black & White):
	```sh
    ./screen_mode.sh reading 1
	```
	*Completely removes color, creating a black-and-white display for maximum focus and reduced distractions.*

### Notes

The grayscale value can be set between 0 and 1, where 0 keeps full colors and 1 makes the screen completely black and white.
Adjust the value to find the most comfortable setting for reading.

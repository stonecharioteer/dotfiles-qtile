#!/bin/bash

hour=$(date +%H)

# Reset any existing redshift settings
redshift -x -m randr

if [ "$hour" -ge 6 ] && [ "$hour" -lt 8 ]; then
	redshift -O 5000 -m randr
	dunstify "Redshift: Morning (5000K)"
elif [ "$hour" -ge 8 ] && [ "$hour" -lt 17 ]; then
	dunstify "Redshift: Day (6500K - no adjustment)"
	# No redshift applied for 6500K — natural display
elif [ "$hour" -ge 17 ] && [ "$hour" -lt 20 ]; then
	redshift -O 4500 -m randr
	dunstify "Redshift: Evening (4500K)"
else
	redshift -O 3500 -m randr
	dunstify "Redshift: Night (3500K)"
fi

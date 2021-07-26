#!/bin/bash
clear
echo -e "
	-----------------------------| Dash Setup |----------------------------------
	
	Before we start, let's introduce each other. I am a script written for your
	convenience, I like to call myself Stardust. What's your name?
	" 
read name
clear
echo "
	-----------------------------| Dash Setup |----------------------------------
	
	Awesome to meet you, $name :-D
	"

while true; do
	read -p "
	
	Now with the pleasantries out of the way - let's make sure that dash is setup
	the right way! All the tweaks we do here are accessible from the Dash to Dock
	settings.
	
	We will only setup the visuals for now, the behaviour of the dash is for you
	to tweak.
			
		Cool? (y/n) " yn
	case $yn in
		[Yy]* ) echo; echo "
		Great, let's do it!"; echo; break;;
		[Nn]* ) echo; echo "
		... ok, you were supposed to hit Y :-/"; echo; exit;;
		* ) echo; echo "
		! You must answer something I understand...  - Y or N"; echo;;
	esac

done


echo "
	--------------------------------| Tweaking |--------------------------------
	"
gsettings set org.gnome.shell.extensions.user-theme name 'carapace40'
echo "	→ Setting user theme to Carapace"
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false
echo "	→ Deactivate built in theme"
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
echo "	→ Shrink the Dash"
gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color true
echo "	→ Use custom background color"
oldBGcolor="$(gsettings get org.gnome.shell.extensions.dash-to-dock background-color)"
gsettings set org.gnome.shell.extensions.dash-to-dock background-color 'rgba(0,0,0,0)'
echo "	... which is like transparent and whatnot *"
gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed true
echo "	→ Nobody likes super-small icons you can't see"
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DEFAULT'
echo "	→ Carapace indicators which get wider the more application windows are open"
echo "
	-----------------------------------------------------------------------------
	
	
	* For reference, your previous background color setting was: $oldBGcolor
	"
echo "
	That's it. The dash should look awesome now.
	Keep it real, $name, and enjoy this version of Carapace :-)
	
	Peace!
	"

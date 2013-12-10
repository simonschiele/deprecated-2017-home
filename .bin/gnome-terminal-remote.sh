#!/bin/sh
#
# small script to use terminal from vim
#

term="gnome-terminal --disable-factory --class 'vimterminal' -t 'vim terminal'"



exit 
#!/bin/sh
# Path: /usr/local/bin/gnome-terminal
if [ "x$*" != "x" ]; then
  /usr/bin/gnome-terminal "$@"
else
  pgrep -u "$USER" gnome-terminal | grep -qv "$$"
  if [ "$?" == "0" ]; then
    WID=`xdotool search --class "gnome-terminal" | head -1`
    xdotool windowfocus $WID
    xdotool key ctrl+shift+t
    wmctrl -i -a $WID
    xdotool type <your-command-here>
  else
    /usr/bin/gnome-terminal
    xdotool type <your-command-here>
  fi
fi





# default applications
export PAGER='less'
export BROWSER='google-chrome'
export MAILER='icedove'
export TERMINAL='gnome-terminal.wrapper --disable-factory'
export OPEN='gnome-open'

# spacer
# todo: vert spacer
alias vr='echo -e "\n\n\n\n\n\n\n\n\n\n"'
alias hr='for i in $( seq ${COLUMNS:-80} ) ; do echo -n "=" ; done ; echo'
export HR=$( hr )

# shorties
alias t='true'
alias f='false'

# default overwrites
alias cp='cp -i -r'
alias less='less'
alias mkdir='mkdir -p'
alias mv='mv -i'
alias rm='rm -i'
alias screen='screen -U'
alias dmesg='dmesg -T --color=auto'
alias wget='wget -c'
alias tmux='TERM=screen-256color-bce tmux'
( which vim >/dev/null ) && alias vi='vim'

# sudo stuff
alias sudo='sudo '
alias sudo.that='eval "sudo $(fc -ln -1)"'

# system
alias create.system_user='sudo adduser --no-create-home --disabled-login --shell /bin/false'
alias observe.pid='strace -T -f -p'

# package and system-config
alias debian.version='lsb_release -a'
alias debian.bugs='bts'
alias debian.packages_custom='debian.packages_list_custom $(grep ^system_type ~/.system.conf | cut -f"2-" -d"=" | sed "s|[\"]||g")'
alias debian.packages_by_size='dpkg-query -W --showformat="${Installed-Size;10}\t${Package}\n" | sort -k1,1n'
alias debian.package_configfiles='dpkg-query -f "\n${Package} \n${Conffiles}\n" -W'

# logs
alias log.dmesg='dmesg -T --color=auto'
alias log.pidgin='find ~/.purple/logs/ -type f -mtime -1 | xargs tail -n 5'
alias log.NetworkManager='sudo journalctl -u NetworkManager'

# find
alias find.dir='find . -type d'
alias find.file='find . ! -type d'
alias find.exec='find . ! -type d -executable'
alias find.last_edited='find . -type f -printf "%T@ %T+ %p\n" | sort -n | tail -n 300'
alias find.last_accessed=''
alias find.tree='find . -print | sed -e "s;[^/]*/;|__;g;s;__|; |;g"'
alias find.deadlinks='find -L -type l'

# date/time stuff
alias date.format='date --help | sed -n "/^FORMAT/,/%Z/p"'
alias date.timestamp='date +%s'
alias date.week='date +%V'
alias date.YY-mm-dd='date "+%Y-%m-%d"'
alias date.YY-mm-dd_HH_MM='date "+%Y-%m-%d_%H-%M"'
alias date.world=worldclock
alias date.stopwatch=stopwatch
alias stopwatch='time read -n 1'

# compression
alias zip.dir='compress zip'
alias rar.dir='compress rar'
alias tar.dir='compress targz'

# mirror
alias mirror.complete='wget --random-wait -r -p -e robots=off -U mozilla'           # mirror website with everything
alias mirror.images='wget -r -l1 --no-parent -nH -nd -P/tmp -A".gif,.jpg"'     # download all images from a site

# filter
alias grep.ip='grep -o "\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}"'
alias grep.url="sed -e \"s|'|\\\"|g\" -e \"s|src|href|g\" | sed -e \"s|href|\nhref|g\" | grep -i -e \"href[ ]*=\" | sed 's/.*href[ ]*=[ ]*[\"]*\(.*\)[\"\ ].*/\1/g' | cut -f'1' -d'\"'"
alias grep.year='grep -o "[1-2][0-9]\{3\}"'
alias highlite='grep --color=yes -e ^ -e'

# random
alias random.mac='openssl rand -hex 6 | sed "s/\(..\)/\1:/g; s/.$//"'
alias random.ip='nmap -iR 1 -sL -n | grep.ip -o'
alias random.lotto='shuf -i 1-49 -n 6 | sort -n | xargs'
random.password() { openssl rand -base64 ${1:-8} ; }
random.hex() { openssl rand -hex ${1:-8} ; }
random.integer() { from=1 ; to=${1:-100} ; [[ -n "${2}" ]] && from=${1} && to=${2} ; echo "f:${from} t:${to}"; echo "$(( RANDOM % ${2:-100} + ${1:-1} ))" ; }

# scan
alias scan.wlans='/sbin/iwlist scanning 2>/dev/null | grep -e "Cell" -e "Channel:" -e "Encryption" -e "ESSID" -e "WPA" | sed "s|Cell|\nCell|g"'

# media 
alias mplayer_left='mplayer -xineramascreen 0'
alias mplayer_right='mplayer -xineramascreen 1'
alias alsa.silent='for mix in PCM MASTER Master ; do amixer -q sset $mix 0 2>/dev/null ; done'
alias alsa.unsilent='for mix in PCM MASTER Master ; do amixer -q sset $mix 90% 2>/dev/null ; done'
alias no.sound='alsa.unsilent'
alias screenshot='import -display :0 -window root ./screenshot-$(date +%Y-%m-%d_%s).png'
alias screendump='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq ./screendump-$(date +%Y-%m-%d_%s).mpg'
alias screenvideo='screendump'

# synergy
alias synergys.custom='[ -e ~/.synergy/$( hostname -s ).conf ] && synergys --daemon --restart --display ${DISPLAY:-:0} --config ~/.synergy/$( hostname -s ).conf 2> ~/.log/synergys.log >&2 || echo "no config for this host available"'
alias synergyc.custom='[ -e ~/.synergy/$( hostname -s ).conf ] && synergyc --daemon --restart --display ${DISPLAY:-:0} --name $( hostname -s ) $( ls ~/.synergy/ | grep -iv "$( hostname -s ).conf" | head -n1 | sed "s|\.conf$||g" ) 2> ~/.log/synergyc.log >&2'
alias synergy.start='kill.synergy ; synergys.custom ; synergyc.custom'
alias kill.synergy='killall -9 synergyc synergys 2>/dev/null ; true'

# show.*
alias show.ip_remote='addr=$( dig +short myip.opendns.com @resolver1.opendns.com | grep.ip ) ; echo ${addr:-$( wget -q -O- icanhazip.com | grep.ip )}'
alias show.ip_local='LANG=C /sbin/ifconfig | grep -o -e "^[^\ ]*" -e "^\ *inet addr:\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}" | tr "\n" " " | sed -e "s|\ *inet addr||g" -e "s|\ |\n|g" -e "s|:|: |g" | grep.ip --color=auto'
alias show.ip='show.ip_local ; echo -e "remote: $( color red_background )$( show.ip_remote )"'
alias show.io='echo -n d | nmon -s 1'
alias show.tcp='sudo netstat -atp'
alias show.tcp_stats='sudo netstat -st'
alias show.udp='sudo netstat -aup'
alias show.udp_stats='sudo netstat -su'
alias show.window_class='xprop | grep CLASS'
alias show.resolution='LANG=C xrandr -q | grep -o "current [0-9]\{3,4\} x [0-9]\{3,4\}" | sed -e "s|current ||g" -e "s|\ ||g"'
alias show.certs='openssl s_client -connect ' 

# tools
alias ssh.untrusted='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias speedtest='wget -O- http://cachefly.cachefly.net/200mb.test > /dev/null'
alias calculator='bc -l'
alias calc='calculator'
alias html.strip='sed -e "s|<[^>]*>||g"'
alias html.umlaute='sed -e "s|ü|\&uuml;|g" -e "s|Ü|\&Uuml;|g" -e "s|ä|\&auml;|g" -e "s|Ä|\&Auml;|g" -e "s|ö|\&ouml;|g" -e "s|Ö|\&Ouml;|g" -e "s|ß|\&szlig;|g"' # todo: untested
alias http.response='lwp-request -ds'
alias show.battery='upower -d | grep -e state -e percentage -e time | sort -u | tr "\n" " " | sed "s|^[^0-9]*\([0-9]*%\)[^:]*:\ *\([^\ ]*\)[^0-9\.]*\([0-9\.]*\)[^0-9]*$|(\1, \2, \3h)|g"; echo'
alias show.keycodes='xev | grep -e keycode -e button'
alias patch.from_diff='patch -Np0 -i'
alias show.usb_sticks='for dev in $( udisks --dump | grep device-file | sed "s|^.*\:\ *\(.*\)|\1|g" ) ; do udisks --show-info ${dev} | grep -qi "removable.*1" && echo ${dev} ; done ; true'
alias btc.worldwide='wget -q -O- https://bitpay.com/api/rates | json_pp'
alias btc='echo -e "€: $( btc.worldwide | grep -C2 Euro | grep -o [0-9\.]* )" ; echo "$: $( btc.worldwide | grep -C2 USD | grep -o [0-9\.]* )"'
alias kill.chrome='echo kill -9 $( ps aux | grep -i chrome | awk {"print $2"} | xargs ) 2>/dev/null'
alias strip.doubleslash='sed "s|[/]\+|/|g"'
alias iso.grml='iso=$( ls -rt /share/Software/images/grml96*iso 2>/dev/null | tail -n1 ) ; iso=${iso:-$( find /boot -iname "grml*iso" 2>/dev/null )} ; iso=${iso:-$( find ~/ -iname "*grml*iso" 2>/dev/null | tail -n1 )} ; echo "$iso"'
alias create.qcow='next=$( printf "%02d\n" "$(( $( ls image_[0-9]*.img 2>/dev/null | grep -o [0-9]* | sort -n | tail -n1 ) + 1 ))" ) ; qemu-img create -f qcow2 -o preallocation=metadata image_${next}.img'
alias kvm.hd='kvm -m 1024 -boot c -hda'
alias kvm.grml+hd='iso=$( iso.grml ) ; kvm -cdrom ${iso} -m 1024 -boot d -hda'

# host/setup specific
if ( grep -iq work /etc/hostname ) ; then
    alias scp='scp -l 30000'
    alias windows.connect='rdesktop -kde -a 16 -g 1280x1024 -u sschiele 192.168.80.55'
    alias wakeonlan.windows='wakeonlan 00:1C:C0:8D:0C:73'
elif [ $( whereami ) = 'home' ] ; then
    alias wakeonlan.mediacenter='wakeonlan 00:01:2e:27:62:87'
    alias wakeonlan.cstation='wakeonlan 00:19:66:cf:82:04'
    alias wakeonlan.cbase='wakeonlan 00:50:8d:9c:3f:6e'
fi

if ( grep -iq 'minit' /proc/cmdline ) ; then
    alias reboot='sudo minit-shutdown -r &'
    alias halt='sudo minit-shutdown -h'
fi

# sorgenkinder
alias show.open_ports='echo -e "User:      Command:   Port:\n----------------------------" ; sudo "lsof -i 4 -P -n | grep -i listen | awk {\"print \$3, \$1, \$9\"} | sed \"s| [a-z0-9\.\*]*:| |\" | sort -k 3 -n | xargs printf \"%-10s %-10s %-10s\n\"" | uniq'
alias log.authlog="sudo grep -e \"^\$( LANG=C date -d'now -24 hours' +'%b %e' )\" -e \"^\$( LANG=C date +'%b %e' )\" /var/log/auth.log | grep.ip | sort -n | uniq -c | sort -n | grep -v \"\$( host -4 enkheim.psaux.de | grep.ip | head -n1 )\" | tac | head -n 10"
alias hooks.run="echo ; systemtype=\$( grep ^systemtype ~/.system.conf | cut -f2 -d'=' | sed -e 's|[\"\ ]||g' -e \"s|'||g\" ) ; for exe in \$( find ~/.hooks/ ! -type d -executable | xargs grep -l \"^hook_systemtype.*\${systemtype}\" | xargs grep -l '^hook_optional=false' ) ; do exec_with_sudo='' ; grep -q 'hook_sudo=.*true.*' \"\${exe}\" && exec_with_sudo='sudo ' || grep -q 'hook_sudo' \"\${exe}\" || exec_with_sudo='sudo ' ; cancel=\${cancel:-false} global_success=\${global_success:-true} \${exe} ; retval=\${?} ; echo ; if test \${retval} -eq 2 ; then echo -e \"CANCELING HOOKS\" >&2 ; break ; elif ! test \${retval} -eq 0 ; then global_success=false ; fi ; done ; \${global_success} || echo -e \"Some hooks could NOT get processed successfully!\n\" ; unset global_success systemtype retval ;"
extensions_video='avi,mkv,mp4,mpg,mpeg,wmv,wmvlv,webm,3g,mov,flv'
extensions_images='png,jpg,jpeg,gif,bmp,tiff,ico,lzw,raw,ppm,pgm,pbm,psd,img,xcf,psp,svg,ai'
extensions_audio='flac,mp1,mp2,mp3,ogg,wav,aac,ac3,dts,m4a,mid,midi,mka,mod,oma,wma'
extensions_documents='doc,xls,abw,chm,pdf,docx,docm,odm,odt,rtf,stw,sxg,sxw,wpd,wps,ods,pxl,sxc,xlsx,xlsm,odg,odp,pps,ppsx,ppt,pptm,pptx,sda,sdd,sxd,dot,dotm,dotx'
extensions_archives='7z,ace,arj,bz,bz2,gz,lha,lzh,rar,tar,taz,tbz,tbz2,tgz,zip'
alias find.videos='find . ! -type d $( echo ${extensions_video}\" | sed -e "s|,|\"\ \-o\ \-iname \"*|g" -e "s|^|\ \-iname \"*|g" )'
alias find.images="find . ! -type d $( echo ${extensions_images}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"
alias find.audio="find . ! -type d $( echo ${extensions_audio}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"
alias find.documents="find . ! -type d $( echo ${extensions_documents}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"
alias find.archives="find . ! -type d $( echo ${extensions_archives}\" | sed -e 's|,|\"\ \-o\ \-iname \"*|g' -e 's|^|\ \-iname \"*|g' )"

alias permissions.normalize="find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d -exec chmod 750 {} \; ; chown \${SUDO_USER:-\$USER}: . -R"
alias permissions.normalize_system="chown \${SUDO_USER:-\$USER}: ~/ -R ; find /home/* /root -maxdepth 0 -type d -exec chmod 700 {} \;"
alias permissions.normalize_web="chown \${SUDO_USER:-\$USER}:www-data . -R ; find . -type f \! -perm -a+x -exec chmod 640 {} \; -o -type f -perm -a+x -exec chmod 750 {} \; -o -type d \( -iname 'log*' -o -iname 'cache' -o -iname 'templates_c' \) -exec chown www-data:\${SUDO_USER:-\$USER} {} -R \; -exec chmod 770 {} \; -o -type d -exec chmod 750 {} \;"

# old stuff
#alias route_via_wlan="for i in \`seq 1 10\` ; do route del default 2>/dev/null ; done ; route add default eth0 ; route add default wlan0 ; route add default gw \"\$( /sbin/ifconfig wlan0 | grep.ip | head -n 1 | cut -f'1-3' -d'.' ).1\""
#alias 2audio="convert2 mp3"
#alias youtube-mp3="clive -f best --exec=\"echo >&2; echo '[CONVERTING] %f ==> MP3' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp3 && rm -f %f\""
#alias youtube="clive -f best --exec=\"( echo %f | grep -qi -e 'webm$' -e 'webm.$' ) && ( echo >&2 ; echo '[CONVERTING] %f ==> MP4' >&2 ; ffmpeg -loglevel error -i %f -strict experimental %f.mp4 && rm -f %f )\""
#alias image2pdf='convert -adjoin -page A4 *.jpeg multipage.pdf'				# convert images to a multi-page pdf
#nrg2iso() { dd bs=1k if="$1" of="$2" skip=300 }

#!/bin/bash

# {{{ Colors

declare -g -A COLORS

COLORS[none]="\e[0m"
COLORS[off]="\e[0m"
COLORS[false]="\e[0m"
COLORS[normal]="\e[0m"

# Basic Colors
COLORS[black]="\e[0;30m"
COLORS[red]="\e[0;31m"
COLORS[green]="\e[0;32m"
COLORS[yellow]="\e[0;33m"
COLORS[blue]="\e[0;34m"
COLORS[purple]="\e[0;35m"
COLORS[cyan]="\e[0;36m"
COLORS[white]="\e[0;37m"

# Bold Colors
COLORS[black_bold]="\e[1;30m"
COLORS[red_bold]="\e[1;31m"
COLORS[green_bold]="\e[1;32m"
COLORS[yellow_bold]="\e[1;33m"
COLORS[blue_bold]="\e[1;34m"
COLORS[purple_bold]="\e[1;35m"
COLORS[cyan_bold]="\e[1;36m"
COLORS[white_bold]="\e[1;37m"

# Underline
COLORS[black_under]="\e[4;30m"
COLORS[red_under]="\e[4;31m"
COLORS[green_under]="\e[4;32m"
COLORS[yellow_under]="\e[4;33m"
COLORS[blue_under]="\e[4;34m"
COLORS[purple_under]="\e[4;35m"
COLORS[cyan_under]="\e[4;36m"
COLORS[white_under]="\e[4;37m"

# Background Colors
COLORS[black_background]="\e[40m"
COLORS[red_background]="\e[41m"
COLORS[green_background]="\e[42m"
COLORS[yellow_background]="\e[43m"
COLORS[blue_background]="\e[44m"
COLORS[purple_background]="\e[45m"
COLORS[cyan_background]="\e[46m"
COLORS[white_background]="\e[47m"
COLORS[gray_background]="\e[100m"

function show.colors() {
    (
        for key in "${!COLORS[@]}" ; do
            echo -e " ${COLORS[$key]} == COLORTEST ${key} == ${COLORS[none]}"
        done
    ) | column -c ${COLUMNS:-120}
}

alias list.colors=show.colors
alias colors.show=show.colors
alias colors.list=show.colors

function color.exists() {
    [ ${COLORS[${1:-none}]+isset} ] && return 0 || return 1
}

function color() {
    ( color.exists ${1:-none} ) && echo -ne "${COLORS[${1:-none}]}"
}

function color.ps1() {
    ( color.exists ${1:-none} ) && echo -ne "\[${COLORS[${1:-none}]}\]"
}

function color.echo() {
    ( color.exists ${1:-black} ) && echo -e "${COLORS[${1:-black}]}${2}${COLORS[none]}"
}

function color.echon() {
    ( color.exists ${1:-black} ) && echo -ne "${COLORS[${1:-black}]}${2}${COLORS[none]}"
}

# }}}

# {{{ Icons

declare -g -A ICONS

ICONS[trademark]='\u2122'
ICONS[copyright]='\u00A9'
ICONS[registered]='\u00AE'
ICONS[asterism]='\u2042'
ICONS[voltage]='\u26A1'
ICONS[whitecircle]='\u25CB'
ICONS[blackcircle]='\u25CF'
ICONS[largecircle]='\u25EF'
ICONS[percent]='\u0025'
ICONS[permille]='\u2030'
ICONS[pilcrow]='\u00B6'
ICONS[peace]='\u262E'
ICONS[yinyang]='\u262F'
ICONS[russia]='\u262D'
ICONS[turkey]='\u262A'
ICONS[skull]='\u2620'
ICONS[heavyheart]='\u2764'
ICONS[whiteheart]='\u2661'
ICONS[blackheart]='\u2665'
ICONS[whitesmiley]='\u263A'
ICONS[blacksmiley]='\u263B'
ICONS[female]='\u2640'
ICONS[male]='\u2642'
ICONS[airplane]='\u2708'
ICONS[radioactive]='\u2622'
ICONS[ohm]='\u2126'
ICONS[pi]='\u220F'
ICONS[cross]='\u2717'
ICONS[fail]='\u2717'
ICONS[error]='\u2717'
ICONS[check]='\u2714'
ICONS[ok]='\u2714'
ICONS[success]='\u2714'
ICONS[warning]='⚠'

function show.icons() {
    (
        for key in "${!ICONS[@]}" ; do
            echo -e " ${ICONS[$key]} : ${key}"
        done
    ) | column -c ${COLUMNS:-80}
}

alias list.icons=show.icons
alias icons.show=show.icons
alias icons.list=show.icons

function icon.exists() {
    [ ${ICONS[${1:-none}]+isset} ] && return 0 || return 1
}

function icon() {
    ( icon.exists ${1:-none} ) && echo -ne "${ICONS[${1:-none}]}"
}

function icon.color() {
    local icon=${1:-fail}
    local color=${2:-red}
    local status=0

    if ( ! icon.exists $icon ) || ( ! color.exists $color ) ; then
        status=1
        icon='fail'
        color='red'
    fi

    color.echon $color $( icon $icon )
    return ${status}
}

# }}}

# {{{ functions

# default output
function es_msg() {
    echo "${2}> $1"
}

function es_warning() {
    es_msg "$1" "WARNING"
}

function es_error() {
    es_msg "$1" "ERROR"
}

# debug output (will be printed only if debug is enabled)
function es_debug() {
    ${ESSENTIALS_DEBUG} && es_msg "$1" "DEBUG"
}

# reload essentials libs
function es_reload() {
    reset
    . "$HOME"/.bashrc
}

# toggle debug
function es_debug_toggle() {
    ( $ESSENTIALS_DEBUG ) && export ESSENTIALS_DEBUG=false || export ESSENTIALS_DEBUG=true
    es_reload
    es_info
}

function es_info() {
    es_banner
    es_msg "$( color white_bold )ENVIRONMENT:$( color )"
    es_msg " USER: ${ESSENTIALS_USER}"
    es_msg " HOME: ${ESSENTIALS_HOME}/"
    es_msg " DIR CACHE: ${ESSENTIALS_DIR_CACHE}/"
    es_msg " DIR LOG: ${ESSENTIALS_DIR_LOG}/"
    es_msg " SUDO: ${ESSENTIALS_IS_SUDO} (unlocked: ${ESSENTIALS_IS_SUDO_UNLOCKED})"
    es_msg " ROOT: ${ESSENTIALS_IS_ROOT}"
    es_msg " SSH: ${ESSENTIALS_IS_SSH}"
    es_msg " MOSH: ${ESSENTIALS_IS_MOSH}"
    es_msg " TMUX: ${ESSENTIALS_IS_TMUX}"
    es_msg " SCREEN: ${ESSENTIALS_IS_SCREEN}"
    es_msg
    es_msg "$( color white_bold )SSH AGENT:$( color )"
    es_msg " AGENT RUNNING: ${ESSENTIALS_HAS_SSHAGENT} (pid ${SSH_AGENT_PID:-UNKNOWN})"
    es_msg
    es_msg "$( color white_bold )EXTERNALS:$( color )"
    es_msg " BASH VERSION: ${BASH_VERSION}"
    es_msg " GIT VERSION: ${ESSENTIALS_VERSION_GIT}"
    es_msg " VIM VERSION: ${ESSENTIALS_VERSION_VIM}"
    es_msg " HOME REPO: ${ESSENTIALS_VERSION_HOME} (commit $( es_repo_version ${ESSENTIALS_HOME} | sed 's| |, |'))"
    es_msg
    es_msg "$( color white_bold )ESSENTIALS:$( color )"
    es_msg " VERSION: ${ESSENTIALS_VERSION} (commit $( es_repo_version ${HOME} | sed 's| |, |'))"
    es_msg " DIR ESSENTIALS: ${HOME}/"
    es_msg " DEBUG: ${ESSENTIALS_DEBUG}"
    es_msg " LOG: ${ESSENTIALS_LOG} (-> ${ESSENTIALS_LOGFILE})"
    es_msg " FUNCTIONS: $( grep -c "^[ ]*function[^)]\+)" "$HOME"/.bash_functions )"
    es_msg " ALIASES: $( grep -c "^[ ]*alias [^ ]\+=" "$HOME"/.bash_aliases | wc -l )"
    es_msg
    es_msg "$( color white_bold )APPLICATIONS:$( color )"
    es_msg " EDITOR: ${EDITOR}"
    es_msg " PAGER: ${PAGER}"
    es_msg " BROWSER: ${BROWSER}"
    es_msg " TERMINAL: ${TERMINAL}"
    es_msg
}

function es_check_version() {
    local required_version=$( echo "$1" | sed 's|[^0-9\.]*||g' )
    local compare_version=$( echo "$2" | sed 's|[^0-9\.]*||g' )
    local higher_version=$( echo -e "${required_version}\n${compare_version}" | sort -V | head -n1 )
    [[ "$required_version" = "${higher_version}" ]]
}

function es_depends() {
    local depends_name="$1"
    local depends_type="${2:-bin}"
    local available=false

    case "$depends_type" in
        bin|which|executable)
            which "$depends_name" >/dev/null && available=true
            ;;

        dpkg|deb|debian)
            es_depends dpkg || exit_error 'please install dpkg if you want to check depends via dpkg'
            dpkg -l | grep -iq "^ii\ \ ${depends_name}\ " && available=true
            ;;

        pip)
            local pip_version pip_output
            es_depends pip || exit_error 'please install (python-)pip, to check depends via pip'

            pip_version=$( pip --version | awk '{print $2}' )
            if ( es_check_version 1.3 "$pip_version" ) ; then
                pip_output=$( pip show "$depends_name" 2>/dev/null | xargs | awk '{print $3"=="$5}' | sed '/^==$/d' )
            else
                pip_output=$( pip freeze 2>/dev/null | grep "^${depends_name}=" )
            fi

            [[ -n "$pip_output" ]] && available=true
            ;;

        *)
            es_depends "$depends_name" bin && available=true
            ;;
    esac

    $available
    return
}

function es_depends_first() {
    local candidate candidate_cmd
    local candidates="$*"
    IFS=","

    for candidate in $candidates ; do
        candidate="${candidate##*( )}"
        candidate="${candidate%%*( )}"
        candidate_cmd=$( echo "$candidate" | cut -f'1' -d' ' )
        if es_depends "$candidate_cmd" ; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

function es_depends_essentials() {
    if ( [ -z "$PS1" ] || [ -z "$BASH_VERSION" ] ) ; then
        es_error "shell is not bash"
        return 1
    fi

    # toilet|figlet
    # git
    # vim (why?)
    # pstree (psmisc)

    return 0
}

function es_banner() {
    if [ $( find /usr/share/figlet/ /usr/local/figlet/ /usr/local/share/figlet/ /usr/share/toilet/ /usr/local/toilet/ /usr/local/share/toilet/ -iname "future\.*" 2>/dev/null | wc -l ) -gt 0 ] ; then
        local font="-f future"
    fi

    if es_depends "toilet" "bin" ; then
        toilet -F border ${font} "essentials" --gay | es_center_aligned
        toilet ${font} -w 120 "simons bash workflow" --gay | es_center_aligned
    elif es_depends "figlet" "bin" ; then
        figlet ${font} "essentials" | es_center_aligned
        figlet ${font} -w 120 "simons bash workflow" | es_center_aligned
    else
        echo "ESSENTIALS" | es_center_aligned
        echo "simons bash workflow" | es_center_aligned
    fi
}

function es_center() {
    local data line
    
    if es_called_by_pipe ; then
        while read line ; do
            data="${data}${line}\n"
        done
        data=$( echo "${data}" | sed 's|\\n$||g' )
    else
        data="${@}"
    fi

    echo -e "${data}" | while read line ; do
        local length=$( echo ${line} | sed -r "s:\x1B\[[0-9;]*[mK]::g" | wc -m )
        seq 1 $((( ${COLUMNS} - ${length}) / 2 )) | while read i ; do
            echo -n " "
        done
        echo -e "$line"
    done
}

function es_center_aligned() {
    local data line
    
    if es_called_by_pipe ; then
        while read line ; do
            data="${data}${line}\n"
        done
        data=$( echo "${data}" | sed 's|\\n$||g' )
    else
        data="${@}"
    fi

    echo -e "${data}" | while read line ; do
        if [ -z "$length" ] ; then
            local length=$( echo ${line} | sed -r "s:\x1B\[[0-9;]*[mK]::g" | wc -m )
        fi
        seq 1 $((( ${COLUMNS} - ${length}) / 2 )) | while read i ; do
            echo -n " "
        done
        echo -e "$line"
    done
}

function es_header() {
    echo -e "\n$( es_center_aligned "${@}" )\n"
}

function es_repo_version() {
    local repo="${@:-${HOME}}"
    
    es_debug "updating repo ${repo}"
    cd "${repo}"
    if [ -e ".git" ] ; then
        git log --pretty=format:'%h %cr' -1
    elif [ -e ".hg" ] ; then
        cd $OLDPWD
        es_error "mercurial verion not implemented"
        return 1
    elif [ -e ".svn" ] ; then
        cd $OLDPWD
        es_error "SVN version not implemented"
        return 1
    elif [ -d "CVS" ] ; then
        cd $OLDPWD
        es_error "CVS versoin not implemented"
        return 1
    else
        cd $OLDPWD
        es_error "couldn't find repo type for: $repo"
        return 1
    fi
    local status=$?
    cd $OLDPWD
    
    return $status
}

function es_repo_version_date() {
    local repo="${@:-${HOME}}"
    cd "${repo}"
    local orig_date=$( git log --pretty=format:'%ci' -1 | awk {'print $1'} )
    local from_date=$( date "--date=$orig_date -1 day" +%Y-%m-%d )
    local to_date=$( date "--date=$orig_date +1 day" +%Y-%m-%d )
    local commits=$(( $( git log --pretty=format:'%h %cr' --since=${from_date} --until=${to_date} | wc -l ) + 1 ))
    echo ${from_date//-/}~${commits}
    cd "${OLDPWD}"
}

function es_called_by_pipe() {
    [[ -p /dev/stdin ]]
}

function es_called_by_include() {
    [[ "$( readlink -f ${0} )" != "$( readlink -f ${BASH_SOURCE[0]} )" ]]
}

function es_called_by_exec() {
    [[ "$( readlink -f ${0} )" == "$( readlink -f ${BASH_SOURCE[0]} )" ]]
}

# }}}

# helper
export BOOLEAN=(true false)
export EXTENSIONS_VIDEO='avi,mkv,mp4,mpg,mpeg,wmv,wmvlv,webm,3g,mov,flv'
export EXTENSIONS_IMAGES='png,jpg,jpeg,gif,bmp,tiff,ico,lzw,raw,ppm,pgm,pbm,psd,img,xcf,psp,svg,ai'
export EXTENSIONS_AUDIO='flac,mp1,mp2,mp3,ogg,wav,aac,ac3,dts,m4a,mid,midi,mka,mod,oma,wma,opus'
export EXTENSIONS_DOCUMENTS='asc,rtf,txt,abw,zabw,bzabw,chm,pdf,doc,docx,docm,odm,odt,ods,ots,sdw,stw,wpd,wps,pxl,sxc,xlsx,xlsm,odg,odp,pps,ppsx,ppt,pptm,pptx,sda,sdd,sxd,dot,dotm,dotx,mobi,prc,epub,pdb,prc,tpz,azw,azw1,azw3,azw4,kf8,lit,fb2,md'
export EXTENSIONS_ARCHIVES='7z,s7z,ace,arj,bz,bz2,bzip,bzip2,gz,gzip,lha,lzh,rar,r0,r00,tar,taz,tbz,tbz2,tgz,zip,rpm,deb,xz'

## find (real) user/home
#export ESSENTIALS_USER="${ESSENTIALS_USER:-${CONFIG['user']:-${SUDO_USER:-${USER}}}}"
#export ESSENTIALS_HOME="${ESSENTIALS_HOME:-${CONFIG['home']:-$( getent passwd ${ESSENTIALS_USER} | cut -d':' -f6 )}}"
#export ESSENTIALS_USER="${ESSENTIALS_USER:-${SUDO_USER:-${USER}}}"
#export ESSENTIALS_HOME="${ESSENTIALS_HOME:-$( getent passwd ${ESSENTIALS_USER} | cut -d':' -f6 )}"

## essential settings
#export ESSENTIALS_DIR_PKGLISTS="${ESSENTIALS_HOME}/.packages"
#export ESSENTIALS_DIR_FONTS="${ESSENTIALS_HOME}/.fonts"
#export ESSENTIALS_DIR_WALLPAPERS="${ESSENTIALS_HOME}/.backgrounds"
#export ESSENTIALS_DIR_LOG="${ESSENTIALS_HOME}/.log"
#export ESSENTIALS_DIR_CACHE="${ESSENTIALS_HOME}/.cache"
#export ESSENTIALS_LOGFILE="${CONFIG['logfile']:-${ESSENTIALS_DIR_LOG}/essentials.log}"
#export ESSENTIALS_CACHEFILE="${ESSENTIALS_DIR_CACHE}/essentials.cache"
#export ESSENTIALS_DEBUG="${ESSENTIALS_DEBUG:-${CONFIG['debug']:-false}}"
#export ESSENTIALS_LOG="${ESSENTIALS_LOG:-${CONFIG['log']:-true}}"
#export ESSENTIALS_COLORS="${ESSENTIALS_COLORS:-${CONFIG['colors']:-true}}"
#export ESSENTIALS_UNICODE="${ESSENTIALS_UNICODE:-${CONFIG['unicode']:-true}}"
#export ESSENTIALS_VERSION=$( es_repo_version_date "$HOME" )
#export ESSENTIALS_VERSION_VIM=$( vim --version | grep -o "[0-9.]\+" | head -n 1 )
#export ESSENTIALS_VERSION_GIT=$( git --version | sed 's/git version //' )
#export ESSENTIALS_VERSION_HOME=$( es_repo_version_date ${ESSENTIALS_HOME} )
#export ESSENTIALS_IS_SUDO=$( pstree -s "$$" | grep -qi 'sudo' ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_IS_SUDO_UNLOCKED=$( sudo -n echo -n 2>/dev/null ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_IS_ROOT=$( [ $( id -u ) -eq 0 ] && ! ${ESSENTIALS_IS_SUDO} ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_IS_UID0=$( ${ESSENTIALS_IS_SUDO} || ${ESSENTIALS_IS_ROOT} ; echo ${BOOLEAN[$?]} )  # rename
#export ESSENTIALS_IS_SSH=$( pstree -s "$$" | grep -qi 'ssh' ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_IS_MOSH=$( pstree -s "$$" | grep -qi 'mosh' ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_IS_TMUX=$( pstree -s "$$" | grep -qi 'tmux' ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_IS_SCREEN=$( pstree -s "$$" | grep -qi 'screen' ; echo ${BOOLEAN[$?]} )
#export ESSENTIALS_HAS_SSHAGENT=$( [ -n "$( ps hp ${SSH_AGENT_PID} 2>/dev/null )" ] ; echo ${BOOLEAN[$?]} )

REAL_UID=${SUDO_UID:-$UID}
REAL_GID=${SUDO_GID:-$GID}
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$( getent passwd "$REAL_USER" | cut -d: -f6 )

export REAL_UID REAL_GID REAL_USER REAL_HOME

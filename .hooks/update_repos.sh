#!/bin/bash
hook_name=update_repos
hook_version=0.2
hook_systemtypes="minimal server workstation laptop"    # optional, default: empty
hook_optional=false                                     # optional, default: true
hook_once=false                                         # optional, default: true
hook_sudo=false                                         # optional, default: true
[ -r ~/.hooks/helper.sh ] && . ~/.hooks/helper.sh || ( echo "ERROR: '~/.hooks/helper.sh' not found" ; exit 1 )
###########################################################

for repo in $( find /usr/local/src/ ${real_home} -type d -name ".git" 2>/dev/null )
do
    untracked_content=false
    local_changes=false
    local_commits=false
    remote_changes=false
    submodules=false

    cd $( dirname "$repo" )
    git remote update >/dev/null 2>&1

    if ! ( LANG=C git status -uno | grep -q "Your branch is up-to-date with" ) ; then
        remote_changes=true
    fi

    if ( LANG=C git status | grep -q "Untracked files:" ) ; then
        untracked_content=true
    fi

    if ( LANG=C git status | grep -q "Your branch is ahead of" ) ; then
        local_commits=true
    fi

    if ( LANG=C git status 2>&1 | grep -q "modified:" ) ; then
        local_changes=true
    fi

    if [[ $( git submodule status | wc -l ) > 0 ]] ; then
        submodules=true
    fi

    if ( $local_changes || $local_commits || $untracked_content || $remote_changes ) ; then
        echo "> $( dirname $repo )"
    fi

    if ( $local_changes ) ; then
        echo "  * local changes"
    fi

    if ( $local_commits ) ; then
        echo "  * local commits"
    fi

    if ( $untracked_content ) ; then
        echo "  * untracked content"
    fi

    if ( $remote_changes ) ; then
        echo "  * remote updates"
        git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit HEAD..origin/$( git branch | grep "^\*\ " | sed 's|^\*\ ||g' )
        git pull
    fi

    if ( $submodules ) ; then
        echo -n
        #git submodule init
        #git submodule update --recursive
    fi

    if ( $local_changes || $local_commits || $untracked_content || $remote_changes ) ; then
        echo ""
    fi

    cd $OLDPWD
done


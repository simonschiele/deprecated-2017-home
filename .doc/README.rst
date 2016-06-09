# Simons dotfiles
> my dotfiles. I wouldn't survive my daily battles without these...

If you have nice snippets for me don't be shy! :-)
mailto: simon.codingmonkey@googlemail.com


## About this Repo

I use this repository directly as skeleton for my home-directory, therefore
it ignores everything except explicitly added files and directories.


### Subrepos

This repo brings some of my own and some third-party subrepositories.
    
To check out the submodules:
```
$> git submodule init
$> git submodule update
```

To add a new submodule to the repo, do something like this, from repositories
 root dir:
```
$> git submodule add -f https://github.com/simonschiele/dot.vim.git .vim/
```


## About the Bash prompt

The complete logic for the bash prompt can be found in ~/.bash_prompt

My bash prompt is always a littlebit of a problem-child to me. I squeeze way
to many features in there - so it is always to slow and sometimes way to long.

Since the timeout command is not available to bash functions I use a little
hack. ~/.bash_prompt gets sourced by the usual bashrc logic and prepares a
exported PROMPT_COMMAND that calls ~/.bash_prompt by execution (including a
timeout). I'm not happy with this - maybe somebody else found a nicer
solution for this...

## Thirdparty sources

.fonts-failover/        https://github.com/ryanoasis/nerd-fonts/


## License

All code in this repo that was written by me:
[MIT License](http://opensource.org/licenses/MIT)

This repo contains some scripts, libs, tools, ... from other very gifted people
(mostly as sub-repos).
Of course the original license of these aren't touched or changed.


## Authors

**Simon Schiele** ([simon.codingmonkey@gmail.com](mailto:simon.codingmonkey@gmail.com))

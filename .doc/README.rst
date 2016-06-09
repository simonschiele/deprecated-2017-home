================
Simon's dotfiles
================
---------------------------------------------------------
With these configs I fight my daily battle as a developer
---------------------------------------------------------

I use this repository directly as skeleton for my home-directory, therefore
it ignores everything except explicitly added files and directories.

If you have nice tips or a few lines of cool config for me, please don't
hesitate to write me a mail_.


Overview
========

.. contents:: Table of Contents
.. meta::
    :keywords: home, bash, config, dotfiles
    :description lang=en: Simon's homedir, a few config files to
        drive my daily work as a developer.

.. _mail: simon.codingmonkey@gmail.com
.. _website: https://simon.psaux.de/
.. _github project: https://github.com/simonschiele/home
.. _repo http: https://github.com/simonschiele/home
.. _repo git: git://github.com/simonschiele/home.git
.. _repo ssh: git@github.com:simonschiele/home.git
.. _website dotfiles vim: https://github.com/simonschiele/dot.vim.git
.. _website dotfiles awesome: https://github.com/simonschiele/dot.awesome.git
.. _website dotfiles i3: https://github.com/simonschiele/dot.i3.git


Repositories
============

GitHub repos
------------

* `https://github.com/simonschiele/home <github project_>`_ (github, web)
* `https://github.com/simonschiele/home <repo http_>`_ (github, clone - http)
* `git://github.com/simonschiele/home.git <repo git_>`_ (github, clone - git)
* `git@github.com:simonschiele/home.git <repo ssh_>`_ (github, clone - ssh)


Content
-------

.. code-block::

    /
    |
    |_ .bashrc.d/
    |
    |_ .bash_completion.d/
    |
    |_ .bin/
    |
    |_ .config/
    |
    \_ docs/README.rst            - This help file


Setup / How to use this config
==============================

Install
-------
To use this configuration, just replace your home directory with 
this configset ;-)

.. code-block:: bash

    # Backup existing home
    $> mv -f /home/$USER /home/${USER}.backup

    # Clone the config repo
    $> git clone <repo> /home/$USER

    # Clone subrepos (plugins)
    $> cd ~/
    $> git submodule update --init --recursive


About the Bash prompt
=====================

The complete logic for the bash prompt can be found in ~/.bash_prompt

My bash prompt is always a littlebit of a problem-child to me. I squeeze way
to many features in there - so it is always to slow and sometimes way to long.

Since the timeout command is not available to bash functions I use a little
hack. ~/.bash_prompt gets sourced by the usual bashrc logic and prepares a
exported PROMPT_COMMAND that calls ~/.bash_prompt by execution (including a
timeout). I'm not happy with this - maybe somebody else found a nicer
solution for this...

Thirdparty sources
==================

.. list-table::
    :header-rows: 1

    * - what
      - source
    * - .fonts-failover/*
      - https://github.com/ryanoasis/nerd-fonts/


License
=======

All code in this repo that was written by me:
[MIT License](http://opensource.org/licenses/MIT)

This repo contains some scripts, libs, tools, ... from other very gifted people
(mostly as sub-repos).
Of course the original license of these aren't touched or changed in any way.


Authors
=======
**Simon Schiele** (`mail_ <mail_>`_)

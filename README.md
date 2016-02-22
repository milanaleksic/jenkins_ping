# Jenkins Ping

[![Build Status](https://semaphoreci.com/api/v1/milanaleksic/jenkins_ping/branches/master/badge.svg)](https://semaphoreci.com/milanaleksic/jenkins_ping)

Command line for Jenkins pipeline overview

![Current state](current_state.png "Current state")

## How to run

Please run application with `--help` to see all options.

Application has 2 modes of running ncurses-like (*advanced*) and dump-to-console (the *simple* mode). Application will try to activate the advanced one and will fallback to simple one if it detects the advanced is not possible (for example out of an IDE). You can also force the simple mode of working via adequate command line switch.

## Highly experimental

This app is in early stages of development. It *works for me* but it *might not work for you* (if not, I am sorry, but this is just yet another a hobby project of mine).

## Building, tagging and artifact deployment

This is `#golang` project. I used Go 1.5.

`go get github.com/milanaleksic/jenkins_ping` should be enough to get the code and build.

To build project you can execute (this will get from internet all 3rd party utilites needed for deployment: upx, go-upx, github-release):

    make prepare

You can start building project using `make`, even `deploy` to Github (if you have privileges to do that of course).

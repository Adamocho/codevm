# VSCODE VERSION MANAGER

Any vscode version on any \*nix machine

## Table of content
- [Intro](#intro)
- [About](#about)
    - [Short story](#short-story-about-the-origins-of-this-project)

## Intro

`codevm` allows you to quickly download and install any version of vscode via the command line.

**Example:**
```
# Download version 1.65.0
$ codevm get 1.65.0
VsCode 1.65.0 downloaded

# Get the latest stable release
$ codevm get stable
VsCode stable downloaded

# Get and install the insiders version
$ codevm getin insider
VsCode insider installed (try out the 'code' command)
```

Simple and intuitive!

## About

`codevm` is a version manager for vscode. `codevm` works on any POSIX-compliant shell like bash.

### Short story about the origins of this project

My wrath knew no bounds when I realized that the distribution of linux, which I was using at the time, did not include a proper vscode package in the package manager's repository of theirs. And I then told to myself "Wouldn't it be nice, if I could have **any version** of vscode at my beck and call?" - the idea was born.
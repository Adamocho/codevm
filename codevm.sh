#!/bin/bash

CODEVM_VERSION="0.1.0"

eval_system_information () {
    CODEVM_ARCH=$(uname -m)
    CODEVM_OS=$(uname -s)
    CODEVM_OS_LIKE=$(cat /etc/os-release | grep ID_LIKE | cut -d '=' -f 2)s


    if [[ $CODEVM_OS =~ (Darwin|darwin) ]]; then
        CODEVM_PACK_ARCH="darwin-universal"
    else
        CODEVM_PACK_ARCH="linux"

        if [[ $CODEVM_OS_LIKE =~ (debian|ubuntu|kali) ]]; then
            CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-deb"
        elif [[ $CODEVM_OS_LIKE =~ (redhat|centos|fedora) ]]; then
            CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-rpm"
        fi
    fi

    if [[ $CODEVM_ARCH =~ (arm|arch) ]]; then
        CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-arm64"
    elif [[ $CODEVM_ARCH =~ (amd64|x86|x86_64|i686|i386|sparc) ]]; then
        CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-x64"
    else
        CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-armhf"
    fi
}

download_package () {
    TIMESTAMP="$(date +%s)"

    mkdir -p "$HOME/vscode_versions/$TIMESTAMP"

    wget -q -P "$HOME/vscode_versions/$TIMESTAMP" --trust-server-names --show-progress "https://update.code.visualstudio.com/$CODEVM_PACK_VERSION/$CODEVM_PACK_ARCH/$CODEVM_PACK_BUILD"
}

download_json () {
    # NO NEED TO DOWNLOAD TO FILE - JUST GREP IF HASH IS CONTAINED IN THE OUTPUT

    # [ "$CODEVM_PACK_VERSION" = "latest" ] && 
    # echo "Go to https://code.visualstudio.com/sha
    # Find your version and compare hashes using:
    #     sha256sum - for version 1.13.0 and above
    #     sha1sum - for versions before 1.13.0
    
    # Example
    #     sha256sum code_1.65.0.deb
    # "


    wget -nc -O "$HOME/vscode_versions/$TIMESTAMP/json" "https://update.code.visualstudio.com/api/versions/$CODEVM_PACK_VERSION/$CODEVM_PACK_ARCH/$CODEVM_PACK_BUILD"
}

install_package () {
    echo "Install"
}

verify_version () {
    [ -z "$1" ] && (echo "No version argument"; exit)

    if [[ ! $1 =~ ^([0-9]\.[0-9]{1,2}\.[0-9]|stable|insider)$ ]]; then
        echo "Supplied version: $1 is not correct"
        exit
    fi

    if [[ $1 =~ ^(stable|insider)$ ]]; then
        CODEVM_PACK_BUILD=$1
        CODEVM_PACK_VERSION="latest"
    else
        CODEVM_PACK_BUILD="stable"
        CODEVM_PACK_VERSION=$1
    fi

    echo "Build: $CODEVM_PACK_BUILD"
    echo "Version: $CODEVM_PACK_VERSION"

    return 0
}

case $1 in
    'check') # Check hash of the installed version
        CODE="$(code --version | head -n 1)" # grep -o '[1-9].[1-9]{1,2}.[1-9]{1,2}
        echo "$CODE"
        ;;

    'get' | 'download') # Download specific version
        eval_system_information; verify_version "$2" && download_package
        ;;

    'getin' | 'getinstall') # Download and install specific verion (GET && INSTALL)
        eval_system_information; verify_version "$2" && download_package && install_package
        ;;

    'install') # Add to $PATH
        echo "Adding to path";;

    'uninstall') # Remove from $PATH
        echo "Uninstalling";;

    'list') # List all available versions (Oh my... how do I do it?)
        echo "listing";;

    'show') # Show specific version info
        echo "Showing something";;

    '' | '-h' | '--help')
        echo "CodeVM - VsCode Version Manager (v$CODEVM_VERSION)
        Usage: 
            codevm [Action] [Options]";;

    *) # Exit the program
        echo "Wrong arguments given: $*
        Type: codevm [-h|--help] to see available options";;
esac
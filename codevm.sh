#!/bin/bash

CODEVM_VERSION="0.1.0"

codevm_help () {
    echo "CodeVM - VsCode Version Manager (v$CODEVM_VERSION)"
    exit 0
}

wrong_args () {
    echo "Wrong arguments given: $*"
    echo "Type codevm [--help] to see available options"
    exit 1
}

get_system_info () {
    CODEVM_ARCH=$(uname -m)
    CODEVM_OS=$(uname -s)
    CODEVM_OS_LIKE=$(cat /etc/os-release | grep ID_LIKE | grep -o '[a-z]*')
}

download_package () {
    #  wget -q -O "code_$2_info.json" "https://update.code.visualstudio.com/api/versions/$2/linux-deb-x64/stable"

    # wget -q --show-progress -O "code_$CODEVM_PACK_VERSION.deb" -P "$HOME/" "https://update.code.visualstudio.com/$CODEVM_PACK_VERSION/linux-deb-x64/$CODEVM_PACK_BUILD"
    wget -P "$HOME/vscode_versions" --trust-server-names "https://update.code.visualstudio.com/$CODEVM_PACK_VERSION/linux-deb-x64/$CODEVM_PACK_BUILD"

    # echo "Error: Probably wget error"; exit 1; 

    # URL= grep -o 'https://[a-zA-Z0-9/.-]*' code_$2.json 
}

install_package () {
    echo "Installing..."
}

is_version_correct () {
    if [[ ! $1 =~ ^([0-9]\.[0-9]{1,2}\.[0-9]|stable|insider)$ ]]; then
        echo "Supplied version: $1 is not correct"
        exit 127
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

[ $# -lt 1 ] && codevm_help

get_system_info

echo $CODEVM_VERSION
echo "$CODEVM_ARCH"
echo "$CODEVM_OS"
echo "$CODEVM_OS_LIKE"

case $1 in
    "check") # Check hash of the installed version
        CODE="$(code --version | head -n 1)" # grep -o '[1-9].[1-9]{1,2}.[1-9]{1,2}
        echo "$CODE"
        ;;

    "download") # Download specific version
        echo "Downloading"
        is_version_correct "$2" && download_package
        ;;

    "install") # Download and install specific verion
        echo "Installing"
        is_version_correct "$2" && download_package
        ;;

    "list") # List all available versions (Oh my... how do I do it?)
        echo "listing"
        ;;

    "show") # Show specific version info
        echo "Showing something"
        ;;

    "upgrade") # For future use
        echo "Upgrading"
        ;;

    *) # Exit the program
        echo "Command $1 not recognized"
        exit 127
        ;;
esac
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
    PACK_URL="https://update.code.visualstudio.com/$CODEVM_PACK_VERSION/$CODEVM_PACK_ARCH/$CODEVM_PACK_BUILD"
    PACK_DIR="$HOME/vscode_versions/$TIMESTAMP"

    echo "Save directory: $PACK_DIR"

    echo "Getting package: $PACK_URL"

    mkdir -p "$PACK_DIR"
    wget -q -P "$PACK_DIR" --trust-server-names --show-progress "$PACK_URL"
}

download_json () {
    [ "$CODEVM_PACK_VERSION" = "latest" ] && 
    JSON_URL="https://code.visualstudio.com/sha?build=$CODEVM_PACK_BUILD" ||
    JSON_URL="https://update.code.visualstudio.com/api/versions/$CODEVM_PACK_VERSION/$CODEVM_PACK_ARCH/$CODEVM_PACK_BUILD"

    echo "Getting json: $JSON_URL"
    wget -q --show-progress -O "$PACK_DIR/json" "$JSON_URL"
}

compare_hash () {
    cd "$PACK_DIR" || (echo "cd failed"; exit)

    PACK_FILE=$(ls --hide="*json*" | tr -d "[:space:]")

    [ -z "$PACK_FILE" ] && (echo "No package file found"; exit)

    echo "Checking sha1sum of $PACK_FILE:"

    PACK_SHA1=$(sha1sum "$PACK_FILE" | cut -d " " -f 1 | tr -d "[:space:]")
    PACK_SHA256=$(sha256sum "$PACK_FILE" | cut -d " " -f 1 | tr -d "[:space:]")

    [ -z "$PACK_SHA1" ] || [ -z "$PACK_SHA256" ] && (echo "File not found"; exit)

    echo "Package sha1sum: $PACK_SHA1"
    echo "Package sha1sum: $PACK_SHA256"

    echo "Checking sha1..."
    [ -n $(grep -q "$PACK_SHA1" "$PACK_DIR/json") ] && (echo "$PACK_FILE matches SHA1") || (echo "SHA1 hash does not match: $PACK_FILE may be corrupt - do not install"; exit)

    echo "Checking sha256..."
    [ -n $(grep -q "$PACK_SHA256" "$PACK_DIR/json") ] && (echo "$PACK_FILE matches SHA256") || (echo "(IGNORE IF CODE VERSION < 1.13.0) SHA256 hash does not match: $PACK_FILE may be corrupt - do not install"; exit)
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
        CODE="$(code --version | head -n 1)"
        echo "$CODE"
        ;;

    'get' | 'download') # Download specific version
        eval_system_information; verify_version "$2" && download_package && download_json && compare_hash
        ;;

    'getin' | 'getinstall') # Download and install specific verion (get & in-stall)
        eval_system_information; verify_version "$2" && download_package && download_json && compare_hash
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
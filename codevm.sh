#!/usr/bin/sh

CODEVM_VERSION="0.1.0"

initialize () {
    CODEVM_ARCH=$(uname -m)
    CODEVM_OS=$(uname -s)
    CODEVM_OS_LIKE=$(grep ID_LIKE < /etc/os-release | cut -d '=' -f 2)
    CODEVM_DOCS_URL="https://code.visualstudio.com/docs"
    CODEVM_CURRENT_URL="https://code.visualstudio.com/updates"
    INSTALL_PATH="/usr/bin/codevm"
    CODEVM_DIR="$HOME/vscode_versions"

    if echo "$CODEVM_OS" | grep -Eq "(Darwin|darwin)"; then
        CODEVM_PACK_ARCH="darwin-universal"
    else
        CODEVM_PACK_ARCH="linux"

        if echo "$CODEVM_OS_LIKE" | grep -Eq "(debian|ubuntu|kali)"; then
            CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-deb"
        elif echo "$CODEVM_OS_LIKE" | grep -Eq "(redhat|centos|fedora)"; then
            CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-rpm"
        fi
    fi

    if echo "$CODEVM_ARCH" | grep -Eq "(arm|arch)"; then
        CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-arm64"
    elif echo "$CODEVM_ARCH" | grep -Eq "(amd64|x86|x86_64|i686|i386|sparc)"; then
        CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-x64"
    else
        CODEVM_PACK_ARCH="$CODEVM_PACK_ARCH-armhf"
    fi

    [ -d "$CODEVM_DIR" ] || mkdir -p "$CODEVM_DIR/list.txt"
}

download_package () {
    [ -d "$PACK_DIR" ] || mkdir -p "$PACK_DIR"

    PACK_URL="https://update.code.visualstudio.com/$CODEVM_PACK_VERSION/$CODEVM_PACK_ARCH/$CODEVM_PACK_BUILD"

    echo "Save directory: $PACK_DIR"
    echo "Getting package: $PACK_URL"

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
    PACK_FILE=$(find "$PACK_DIR" -type f -not -name json | tr -d "[:space:]")

    [ -z "$PACK_FILE" ] && echo "No package file found" && exit

    PACK_SHA1=$(sha1sum "$PACK_FILE" | cut -d " " -f 1 | tr -d "[:space:]")
    PACK_SHA256=$(sha256sum "$PACK_FILE" | cut -d " " -f 1 | tr -d "[:space:]")

    [ -z "$PACK_SHA1" ] || [ -z "$PACK_SHA256" ] && echo "File not found" && exit

    echo "Vscode package sha1sum: $PACK_SHA1"
    echo "Vscode package sha1sum: $PACK_SHA256"

    printf "\nChecking sha1...      "
    if grep -q "$PACK_SHA1" "$PACK_DIR/json"; then
        echo "sha1 is OK"
    else
        echo "sha1 hash does not match:   $PACK_FILE  may be corrupt   -->     do not install"
        exit
    fi

    [ "$(echo "$CODEVM_PACK_VERSION" | cut -d '.' -f 2)" -lt 13 ] 2> /dev/null && exit

    printf "\n| Vscode version is 1.13.0 or above --> sha256 check required |\n"

    printf "\nChecking sha256...    "
    if grep -q "$PACK_SHA256" "$PACK_DIR/json"; then
        echo "sha256 is OK"
    else
        echo "sha256 hash does not match:   $PACK_FILE  may be corrupt   -->     do not install"
        exit
    fi
}

install_package () {
    echo "Install"
}

verify_version () {
    if ! echo "$1" | grep -Eq "^([0-9]\.[0-9]{1,2}\.[0-9]|stable|insider)$"; then
        echo "Supplied version: $1 is not correct"
        exit
    fi

    if echo "$1" | grep -Eq "^(stable|insider)$"; then
        CODEVM_PACK_BUILD=$1
        CODEVM_PACK_VERSION="latest"
        PACK_DIR="$HOME/vscode_versions/${CODEVM_PACK_BUILD}_$(date +%s | sha1sum | head -c 5)"
    else
        CODEVM_PACK_BUILD="stable"
        CODEVM_PACK_VERSION=$1
        PACK_DIR="$HOME/vscode_versions/$(echo "$CODEVM_PACK_VERSION" | tr -d '.')_$(date +%s | sha1sum | head -c 5)"
    fi

    echo "Build: $CODEVM_PACK_BUILD"
    echo "Version: $CODEVM_PACK_VERSION"
}

initialize

case $1 in
    'check') # Check hash of the installed version
        code --version | head -n 1
        ;;

    'docs' | 'documentation')
        printf "\n      Opening %s \n" "$CODEVM_DOCS_URL"
        xdg-open "$CODEVM_DOCS_URL" &;;

    'summ' | 'summary' | 'view' | 'overview') # View current version
        printf "\n      Opening %s \n" "$CODEVM_CURRENT_URL"
        xdg-open "$CODEVM_CURRENT_URL" &;;

    'get' | 'download') # Download specific version
        verify_version "$2" && download_package && download_json && compare_hash
        ;;

    'getin' | 'getinstall' | 'install') # Download and install specific verion (get & in-stall)
        verify_version "$2" && download_package && download_json && compare_hash
        ;;

    'add') # Add to $PATH
        echo "Adding to path:"
        (set -x; sudo cp "$0" $INSTALL_PATH) || exit 4
        exit 0;;

    'remove') # Remove from $PATH
        (set -x; sudo rm -i $INSTALL_PATH) || exit 4
        exit 0;;

    'update-list' | 'fetch') # List all available versions (stable for now)
        LATEST_VERSION=$(wget -O- "https://code.visualstudio.com/sha" 2> /dev/null | grep -Eo "1\.[0-9]{1,2}\.[0-9]" | head -1 | cut -d "." -f 2 &)
        [ -z "$LATEST_VERSION" ] && exit

        for minor in $(seq 0 "$LATEST_VERSION"); do
            wget -O- "https://update.code.visualstudio.com/api/versions/1.$minor.0/linux-x64/stable" 2> /dev/null | grep -Eo "1\.[0-9]{1,2}\.[0-9]" | head -1 >> "$CODEVM_DIR"/list.txt &
        done

        echo "List saved at $CODEVM_DIR/list.txt"
        ;;

    'list')
        [ -e "$HOME"/vscode_versions/list.txt ] &&
        sort -t '.' -k 2n  "$HOME"/vscode_versions/list.txt ||
        echo "'list.txt' file not found. Use: codevm fetch to create one"
        ;;

    'show') # Show specific version info
        echo "Showing something";;

    '' | '-h' | '--help')
        echo "CodeVM - VsCode Version Manager (v$CODEVM_VERSION)
        Usage: 
            codevm [Action] [Options]";;

    '-v' | '--version')
        echo "v$CODEVM_VERSION";;

    *)
        echo "Wrong arguments given: $*
        Type: codevm [-h|--help] to see available options";;
esac
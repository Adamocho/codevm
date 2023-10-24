#!/usr/bin/sh

VERSION="0.1.0"
INSTALL_PATH="/usr/bin/codevm"
DIR="$HOME/.local/codevm"

# Create directory if doesn't exist.
[ -d "$DIR" ] || mkdir -p "$DIR"

check_os() {
    ARCH=$(uname -m)
    OS=$(uname -s)
    OS_LIKE=$(grep ID_LIKE < /etc/os-release | cut -d '=' -f 2)

    if echo "$OS" | grep -Eq "(Darwin|darwin)"; then
        PACK_ARCH="darwin-universal"
    else
        PACK_ARCH="linux"

        if echo "$OS_LIKE" | grep -Eq "(debian|ubuntu|kali)"; then
            PACK_ARCH="$PACK_ARCH-deb"
        elif echo "$OS_LIKE" | grep -Eq "(redhat|centos|fedora)"; then
            PACK_ARCH="$PACK_ARCH-rpm"
        fi
    fi

    if echo "$ARCH" | grep -Eq "(arm|arch)"; then
        PACK_ARCH="$PACK_ARCH-arm64"
    elif echo "$ARCH" | grep -Eq "(amd64|x86|x86_64|i686|i386|sparc)"; then
        PACK_ARCH="$PACK_ARCH-x64"
    else
        PACK_ARCH="$PACK_ARCH-armhf"
    fi
}

download_package () {
    [ -d "$PACK_DIR" ] || mkdir -p "$PACK_DIR"

    PACK_URL="https://update.code.visualstudio.com/$PACK_VERSION/$PACK_ARCH/$PACK_BUILD"

    echo "Save directory: $PACK_DIR"
    echo "Getting package: $PACK_URL"

    wget -q -P "$PACK_DIR" --trust-server-names --show-progress "$PACK_URL"
}

download_json () {
    [ "$PACK_VERSION" = "latest" ] && 
    JSON_URL="https://code.visualstudio.com/sha?build=$PACK_BUILD" ||
    JSON_URL="https://update.code.visualstudio.com/api/versions/$PACK_VERSION/$PACK_ARCH/$PACK_BUILD"

    echo "Getting json: $JSON_URL"
    wget -q --show-progress -O "$PACK_DIR/json" "$JSON_URL"
}

mark_as_corrupted () {
    PACK_NAME=$("ls $PACK_DIR" | grep -Ev 'json')
    mv -v "$PACK_DIR/$PACK_NAME" "$PACK_DIR/corrupted_$PACK_NAME"

    printf "\033[91mIt is marked as corrupted\033[00m\n"
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
        echo "It matches sha1"
    else
        echo "sha1 hash does not match:   $PACK_FILE  may be corrupt   -->     do not install"
        mark_as_corrupted
        exit
    fi

    [ "$(echo "$PACK_VERSION" | cut -d '.' -f 2)" -lt 13 ] 2> /dev/null && exit

    printf "\n| Vscode version is 1.13.0 or above --> sha256 check required |\n"

    printf "\nChecking sha256...    "
    if grep -q "$PACK_SHA256" "$PACK_DIR/json"; then
        echo "It matches sha256"
    else
        echo "sha256 hash does not match:   $PACK_FILE  may be corrupt   -->     do not install"
        mark_as_corrupted
        exit
    fi
}

verify_version () {
    if ! echo "$1" | grep -Eq "^([0-9]\.[0-9]{1,2}\.[0-9]|stable|insider)$"; then
        echo "Supplied version: $1 is not correct"
        exit
    fi

    if echo "$1" | grep -Eq "^(stable|insider)$"; then
        PACK_BUILD=$1
        PACK_VERSION="latest"
    else
        PACK_BUILD="stable"
        PACK_VERSION=$1
    fi

    PACK_DIR="$DIR/$(printf '%x' "$(date +%s)")"

    printf "Build: %s\n" "$PACK_BUILD"
    printf "Version: %s\n" "$PACK_VERSION"
}

fetch_list() {
    newest_version=$( wget -O- "https://code.visualstudio.com/sha" 2> /dev/null | grep -Eo "1\.[0-9]{1,2}\.[0-9]" | head -1 | cut -d "." -f 2 & )
    [ -z "$newest_version" ] && { printf "\033[92mCouldn't fetch any data - exiting\033[00m"; exit; }

    # From 1.0.0 -> 1.newest.0
    for minor in $( seq 0 "$newest_version" ); do
        link="https://update.code.visualstudio.com/api/versions/1.$minor.0/linux-x64/stable"
        wget -O- "$link" 2> /dev/null | grep -Eo "1\.[0-9]{1,2}\.[0-9]" | head -1 >> "$DIR"/list.txt &
    done
}

case $1 in
    'download')
        verify_version "$2" && download_package && download_json && compare_hash
        ;;

    'install')
        verify_version "$2" && download_package && download_json && compare_hash && install_package
        ;;

    'add')
        (set -x; sudo cp -iv "$0" $INSTALL_PATH) || exit 4
        ;;

    'remove')
        (set -x; sudo rm -iv $INSTALL_PATH) || exit 4
        ;;

    'fetch')
        printf "Fetching data..."
        fetch_list
        printf "List saved at %s/list.txt" "$DIR"
        ;;

    'list')
        [ -e "$DIR/list.txt" ] && {
            sort -t. -k 1,1n -k 2,2n -k 3,3n "/home/adam/.local/codevm/list.txt"
        } || {
            echo "'list.txt' file not found. Use: 'codevm fetch' to create one"
        }
        ;;

    '' | '-h' | '--help')
        printf "CodeVM - VsCode Version Manager (v%s)
        Usage: 
            codevm [Command] [Option]
            
        Commands:
            add
                    Copy this program to \$PATH.

            remove
                    Delete this program from \$PATH.

            download     <stable/insider/X.X.X>
                    Download a specified version of vscode.
                    X.X.X - specific version number, e.g. 1.0.0

            install      <stable/insider/X.X.X>
                    Same as above plus installs the package.

            fetch
                    Get the list of available vscode versions.
                    By default it is saved in ~/.local/codevm/versions-list.txt

            list
                    Works after the 'fetch' command was run.  
                    List available vscode versions.
        
        Options:
            -h | --help
                    Show this help.
                
            -v | --version
                    Show package version.
            "   "$VERSION"
        ;;

    '-v' | '--version')
        printf "codevm v%s" "$VERSION"
        ;;

    *)
        printf "\033[91mWrong arguments given:\033[00m $* \n
        Type: codevm [-h|--help] to see available options\n"
        ;;
esac
#!/bin/bash

dir_home="PretendHome"
dir_doc="PretendDocuments"
dir_last="SecretStuffDir"
secret_file="SuperSecretPassword.txt"
pipe="sync_pipe"

#run in a subshell
childInside() {
    cd "$dir_home/$dir_doc/$dir_last"
    sleep 1
    echo "Using absolute path"
    cat "$(pwd)/$secret_file"
    echo ""
    echo "Using relative path"
    cat "./$secret_file"
}

parentOutside() {
    echo "emulating swap"
    chmod 000 "$dir_home/$dir_doc"
    chmod 000 "$dir_home"
    echo "swap done"
    wait "$1" #wait for child to finish cats
    chmod 700 "$dir_home"
    chmod 700 "$dir_home/$dir_doc"
}

setUp() {
    if [[ ! -d "$dir_home" ]]; then
        mkdir --parents "$dir_home/$dir_doc/$dir_last"
    fi

    chmod 700 "$dir_home"
    chmod 700 "$dir_home/$dir_doc"
    chmod 776 "$dir_home/$dir_doc/$dir_last" #enforce default just in case
    echo $(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo) > "$dir_home/$dir_doc/$dir_last/$secret_file"
}

#I don't want to risk using sudo su
#so it will be emulated with changing permissions to 000
main() {
    setUp
    childInside &
    parentOutside $!
    #don't remove dir aferward so user can do their own testing
}
main

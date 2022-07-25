#!/bin/bash

function setup_prod() {
    log_prefix="/mnt/storage01/polaris/log"
    core_prefix="/mnt/storage00/singularity/users"
    dir_prefix="/home"
}

function rm_log() {
    echo """
    find ${log_prefix}/ -type f -mmin +10080 -exec rm -r {} \;
    """
    local res=1
    find ${log_prefix}/ -type f -mmin +10080 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function rm_core() {
    echo """
    find ${core_prefix} -path \"${core_prefix}/*/workspace/*\" -name core.* -type f -mmin +4320 -exec rm -r {} \;
    """
    local res=1
    find ${core_prefix} -path "${core_prefix}/*/workspace/*" -name core.* -type f -mmin +4320 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function rm_illegal_dir() {
    # todo
    local res=0
    return ${res}
}

function shadow_clean() {
    local res=1
    rm_log
    [ $? -eq 0 ] && res=0
    rm_core
    [ $? -eq 0 ] && res=0
    # rm_illegal_dir
    # [ $? -eq 0 ] && res=0
    return ${res}
}
                                                                                                                                                                                                                                                                              
setup_prod
shadow_clean
exit $?

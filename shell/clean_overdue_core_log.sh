#!/bin/bash

function setup_prod() {
    log_prefix="/mnt/storage01/polaris/log"
    singularity_prefix="/mnt/storage00/singularity/users"
    dir_prefix="/home"
}

function rm_log() {
    echo """
    find ${log_prefix} -type f -mmin +10080 -exec rm -r {} \;
    """
    local res=1
    find ${log_prefix} -type f -mmin +10080 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function rm_core() {
    echo """
    find ${singularity_prefix} -path \"${singularity_prefix}/*/workspace/*\" -name core.* -type f -mmin +4320 -exec rm -r {} \;
    """
    local res=1
    find ${singularity_prefix} -path "${singularity_prefix}/*/workspace/*" -name core.* -type f -mmin +4320 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function rm_model() {
    echo """
    find ${singularity_prefix} -maxdepth 2 -path \"${singularity_prefix}/models/*\" -type d -mmin +7200 -exec rm -r {} \;
    """
    local res=1
    find ${singularity_prefix} -maxdepth 2 -path "${singularity_prefix}/models/*" -type d -mmin +7200 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function rm_big_online_model() {
    echo """
    find ${singularity_prefix} -maxdepth 4 -path \"${singularity_prefix}/*/log/*/[0-9]*\" -type d -mmin +7200 -exec rm -r {} \;
    """
    echo """
    find ${singularity_prefix} -maxdepth 5 -path \"${singularity_prefix}/*/log/*/kfcmodel/[0-9]*\" -type d -mmin +7200 -exec rm -r {} \;
    """
    local res=1
    find ${singularity_prefix} -maxdepth 4 -path "${singularity_prefix}/*/log/*/[0-9]*" -type d -mmin +7200 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    find ${singularity_prefix} -maxdepth 5 -path "${singularity_prefix}/*/log/*/kfcmodel/[0-9]*" -type d -mmin +7200 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function rm_migrate_model() {
    echo """
    find ${singularity_prefix} -maxdepth 3 -path \"${singularity_prefix}/*/workspace/tmp_out\" -type d -mmin +4320 -exec rm -r {} \;
    """
    local res=1
    find ${singularity_prefix} -maxdepth 3 -path "${singularity_prefix}/*/workspace/tmp_out" -type d -mmin +4320 -exec rm -r {} \;
    [ $? -eq 0 ] && res=0
    return ${res}
}

function disc_clean() {
    local res=1
    rm_log
    [ $? -eq 0 ] && res=0
    rm_core
    [ $? -eq 0 ] && res=0
    rm_model
    [ $? -eq 0 ] && res=0
    rm_big_online_model
    [ $? -eq 0 ] && res=0
    rm_migrate_model
    [ $? -eq 0 ] && res=0
    return ${res}
}
                                                                                                                                                                                                                                                                              
setup_prod
disc_clean
exit $?

#!/bin/bash

PROD_HOST="airflowdb-182964-w-3704.dbdns.bilibili.co"
PROD_PORT=3704
PROD_USER="airflow_main"
PROD_PSWD=$(echo "TTA5cE9vWTI3UERueDRoRks4VVFzWGtndVp6YkFUM1YK" | base64 --decode)
PROD_DB="airflow_main"

blackhole_pre_host="10.70.66.18"
blackhole_pre_port=3306
blackhole_pre_user="mlsys"
blackhole_pre_pswd=$(echo "U3VwZXJTZWNyZXQK" | base64 --decode)
# blackhole_pre_db="blackhole_pre"
blackhole_pre_db="blackhole_znn"

polaris_pre_host="10.70.66.18"
polaris_pre_port=3306
polaris_pre_user="mlsys"
polaris_pre_pswd=$(echo "U3VwZXJTZWNyZXQK" | base64 --decode)
# polaris_pre_db="polaris_pre"
polaris_pre_db="polaris_znn"

HDFS_PREFIX="/department/ai/user/maojiangyun/platform/mysql"

backtime=`date +%Y%m%d_%H%M%S`
cache_dir="/tmp/dbsync"

if [ -d ${cache_dir} ]; then
    rm -rf ${cache_dir}
fi
mkdir ${cache_dir}

function _sync_blackhole_table() {
    table_name=$1
    blackhole_prod_db_table="${cache_dir}/${table_name}.prod.sql.${backtime}"
    /usr/bin/mysqldump -h${PROD_HOST} -P${PROD_PORT} -u${PROD_USER} \
        -p${PROD_PSWD} ${PROD_DB} ${table_name} --skip-lock-tables --single-transaction \
        > ${blackhole_prod_db_table}
    /usr/bin/mysql -h${blackhole_pre_host} -P${blackhole_pre_port} -u${blackhole_pre_user} \
        -p${blackhole_pre_pswd} ${blackhole_pre_db} \
        < ${blackhole_prod_db_table}
    rm -f ${blackhole_prod_db_table}
}

function sync_blackhole_db() {
    blackhole_pre_db_bk="${cache_dir}/blackhole.prod.sql.${backtime}"
    /usr/bin/mysqldump -h${blackhole_pre_host}  -P${blackhole_pre_port} -u${blackhole_pre_user} \
        -p${blackhole_pre_pswd} ${blackhole_pre_db} \
        > ${blackhole_pre_db_bk}
    
    _sync_blackhole_table "blackhole_user"
    
    /data/service/hadoop/bin/hadoop fs -put ${blackhole_pre_db_bk} ${HDFS_PREFIX}
}

function _sync_polaris_table() {
    table_name=$1
    polaris_prod_db_table="${cache_dir}/${table_name}.prod.sql.${backtime}"
    /usr/bin/mysqldump -h${PROD_HOST} -P${PROD_PORT} -u${PROD_USER} \
        -p${PROD_PSWD} ${PROD_DB} ${table_name} --skip-lock-tables --single-transaction \
        > ${polaris_prod_db_table}
    /usr/bin/mysql -h${polaris_pre_host} -P${polaris_pre_port} -u${polaris_pre_user} \
        -p${polaris_pre_pswd} ${polaris_pre_db} \
        < ${polaris_prod_db_table}
    rm -f ${polaris_prod_db_table}
}

function sync_polaris_db() {
    polaris_pre_db_bk="${cache_dir}/polaris.prod.sql.${backtime}"
    /usr/bin/mysqldump -h${polaris_pre_host}  -P${polaris_pre_port} -u${polaris_pre_user} \
        -p${polaris_pre_pswd} ${polaris_pre_db} \
        > ${polaris_pre_db_bk}
    
    _sync_polaris_table "polaris_queue"
    _sync_polaris_table "polaris_pool_type"
    _sync_polaris_table "polaris_pool"
    
    /usr/bin/mysql -h${polaris_pre_host} -P${polaris_pre_port} -u${polaris_pre_user} \
        -p${polaris_pre_pswd} ${polaris_pre_db} -e "
        UPDATE polaris_pool SET reserve=0;
        "
    
    /data/service/hadoop/bin/hadoop fs -put ${polaris_pre_db_bk} ${HDFS_PREFIX}
}

sync_blackhole_db
sync_polaris_db

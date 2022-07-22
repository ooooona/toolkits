#!/bin/bash

#################################################################
# !!! 警告起始 !!!
# !!! 本脚本代码逻辑只适用于删除过期【一年（12个月）】以内的数据，超过这个时间逻辑会有问题 !!!
# !!! 警告结束 !!!
#
# WD UUID生成规则：
# 1. 调研任务：通过调用 wdflow.py 脚本生成，规则
#    uuid = '%0.2d%0.2d%0.2d%0.2d%0.2d%0.3d' % (t.month, t.day, t.hour, t.minute, t.second, t.microsecond / 1000)
# 2. 例行任务：通过blackhole平台生成，规则
#    uuid = db.Column(mysql.VARCHAR(64), nullable=False,
#    default=lambda x: str(datetime.now().strftime("%Y%m%d%H%M%S%f")) + "%.4d" % random.randint(0, 9999),
#    server_default=expression.text('""'), comment='任务UUID')
#
# WD Batch Checkpoint
# - 上传：[train_one_day.sh](https://git.bilibili.co/AI/singularity/-/blob/dist/singularity/polaris/scripts/train_one_day.sh#L141)
# - 格式：${SAVE_MODEL_PATH}/${WD UUID}
# - 备注：中间训练结果保存到${SAVE_MODEL_PATH}/${WD UUID}/train_seq/checkpoint-${TRAIN_SEQ_INDX}
#        最终训练结果保存到${SAVE_MODEL_PATH}/${WD UUID}
#
# WD Online Checkpoint
# - 上传：[saver.py](https://git.bilibili.co/AI/singularity/-/blob/dist/singularity/train/util/saver.py#L547)
# - 格式：${SAVE_MODEL_PATH}/'%0.2d%0.2d%0.2d%0.2d%0.2d%0.3d' % (t.month, t.day, t.hour, t.minute, t.second, t.microsecond / 1000)
#
# Preparse：
# - 作用：batch训练前序步骤，调用mr/spark把数据先解析成singularity可读入的格式
# - 上传：[train_seq.py](https://git.bilibili.co/AI/singularity/-/blob/dist/singularity/polaris/train_seq.py#L36)
# - 格式：/department/ai/ml_plat/singularity/preparse/${WD UUID}
#
#################################################################

overdue_pattern="2 month ago"
overdue_year=$(date -d "${overdue_pattern}" +%Y)
overdue_month=$(date -d "${overdue_pattern}" +%m)
overdue_day=$(date -d "${overdue_pattern}" +%d)

cur_month=$(date +%m)

function setup_prod() {
  # @sirius-batch pattern: /${prefix}/${mm}${dd}${???}
  sirius_batch_prefix="/department/ai/sirius"
  # @sirius-online pattern: ${prefix}/${uuid}/${yyyy}${mm}${dd}${HH}
  sirius_online_prefix="/department/ai/sirius/online/backup"

  wd_batch_prefix="/department/ai/ml_plat/singularity/models/wd_gpu"
  wd_online_prefix="/department/ai/ml_plat/singularity/models/wd_gpu_online"
  preparse_prefix="/department/ai/ml_plat/singularity/preparse"
}


function rm_pattern_startwith_yyyy() {
  local pattern=$1
  echo """
  hadoop fs -rm -r \"${sirius_online_prefix}/*/${pattern}\"
  hadoop fs -rm -r \"${wd_batch_prefix}/*/${pattern}\"
  hadoop fs -rm -r \"${preparse_prefix}/${pattern}\"
  """
  local res=1
  hadoop fs -rm -r "${sirius_online_prefix}/*/${pattern}"
  [ $? -eq 0 ] && res=0
  hadoop fs -rm -r "${wd_batch_prefix}/*/${pattern}"
  [ $? -eq 0 ] && res=0
  hadoop fs -rm -r "${preparse_prefix}/${pattern}"
  [ $? -eq 0 ] && res=0
  return ${res}
}

function rm_pattern_startwith_mm() {
  local pattern=$1
  echo """
  hadoop fs -rm -r \"${sirius_batch_prefix}/${pattern}\"
  hadoop fs -rm -r \"${wd_online_prefix}/*/${pattern}\"
  hadoop fs -rm -r \"${preparse_prefix}/${pattern}\"
  """
  local res=1
  hadoop fs -rm -r "${sirius_batch_prefix}/${pattern}"
  [ $? -eq 0 ] && res=0
  hadoop fs -rm -r "${wd_online_prefix}/*/${pattern}"
  [ $? -eq 0 ] && res=0
  hadoop fs -rm -r "${preparse_prefix}/${pattern}"
  [ $? -eq 0 ] && res=0
  return ${res}
}

function shadow_clean() {
  local res=1
  # 删除 2020 ~ ${overdue_year}-1 所有的年
  oyear=$(expr ${overdue_year} - 1)
  if [ ${oyear} -ge 2020 ]; then
    for year in $(seq 2020 ${oyear}); do
      rm_pattern_startwith_yyyy "${year}*"
      [ $? -eq 0 ] && res=0
    done
  fi
  # 删除不在 ${overdue_month} ~ ${cur_month} 所有的月，注意两者之间的关系！！！
  if [ ${overdue_month} -lt ${cur_month} ]; then
    ## 正序，没有跨年
    ### 先删除 [01,overdue_month)
    omonth=$(expr ${overdue_month} - 1)
    if [ ${omonth} -ge 1 ]; then
      for month in $(seq 1 ${omonth}); do
        m=`echo ${month} | awk '{printf("%02d",$0)}'`
        rm_pattern_startwith_yyyy "${overdue_year}${m}*"
        [ $? -eq 0 ] && res=0
        rm_pattern_startwith_mm "${m}*"
        [ $? -eq 0 ] && res=0
      done
    fi
    ### 再删除(cur_month,12]
    cmonth=$(expr ${cur_month} + 1)
    if [ ${cmonth} -le 12 ]; then
      for month in $(seq ${cmonth} 12); do
        m=`echo ${month} | awk '{printf("%02d",$0)}'`
        rm_pattern_startwith_mm "${m}*"
        [ $? -eq 0 ] && res=0
      done
    fi
  elif [ ${overdue_month} -gt ${cur_month} ]; then
    ## 逆序，跨年了
    ### 删除(cur_month, overdue_month)
    cmonth=$(expr ${cur_month} + 1)
    omonth=$(expr ${overdue_month} - 1)
    if [ ${cmonth} -le ${omonth} ]; then
      for month in $(seq ${cmonth} ${omonth}); do
        m=`echo ${month} | awk '{printf("%02d",$0)}'`
        rm_pattern_startwith_yyyy "${overdue_year}${m}*"
        [ $? -eq 0 ] && res=0
        rm_pattern_startwith_mm "${m}*"
        [ $? -eq 0 ] && res=0
      done
    fi
  fi
  # 删除 ${overdue_month} 内所有 [01, ${overdue_day})的天
  oday=$(expr ${overdue_day} - 1)
  if [ ${oday} -ge 1 ]; then
    for day in $(seq 1 ${oday}); do
      d=`echo ${day} | awk '{printf("%02d",$0)}'`
      rm_pattern_startwith_yyyy "${overdue_year}${overdue_month}${d}*"
      [ $? -eq 0 ] && res=0
      rm_pattern_startwith_mm "${overdue_month}${d}*"
      [ $? -eq 0 ] && res=0
    done
  fi
  return ${res}
}

setup_prod
shadow_clean
exit $?

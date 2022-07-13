#!/bin/bash

#################################################################
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

function set_prod() {
  # @sirius-batch pattern: /${prefix}/${mm}${dd}${???}
  sirius_batch_prefix="/department/ai/sirius"
  # @sirius-online pattern: ${prefix}/${uuid}/${yyyy}${mm}${dd}${HH}
  sirius_online_prefix="/department/ai/sirius/online/backup"

  wd_batch_prefix="/department/ai/ml_plat/singularity/models/wd_gpu"
  wd_online_prefix="/department/ai/ml_plat/singularity/models/wd_gpu_online"
  preparse_prefix="/department/ai/ml_plat/singularity/preparse"
}
function set_test() {
  test_hdfs_path_root="/department/ai/user/maojiangyun/clean_test_folder"
  sirius_batch_prefix="${test_hdfs_path_root}/sirius_offline"
  sirius_online_prefix="${test_hdfs_path_root}/sirius_online"

  wd_batch_prefix="${test_hdfs_path_root}/wd_batch_prefix"
  wd_online_prefix="${test_hdfs_path_root}/wd_online"
  preparse_prefix="${test_hdfs_path_root}/preparse"
}

function shadow_clean() {
  year=${overdue_year}
  m=$(expr ${overdue_month} + 0)
  suffix_pattern1="0[1-${m}]*" # wdflow uuid
  suffix_pattern2="${year}0[1-${m}]*" # blackhole uuid

  hadoop fs -rm -r "${sirius_batch_prefix}/${suffix_pattern1}"
  hadoop fs -rm -r "${sirius_online_prefix}/*/${suffix_pattern2}"
  hadoop fs -rm -r "${wd_batch_prefix}/*/${suffix_pattern2}"
  hadoop fs -rm -r "${wd_online_prefix}/*/${suffix_pattern1}"
  hadoop fs -rm -r "${preparse_prefix}/${suffix_pattern1}"
  hadoop fs -rm -r "${preparse_prefix}/${suffix_pattern2}"
}

overdue_pattern="3 month ago"
overdue_year=$(date -d "${overdue_pattern}" +%Y)
overdue_month=$(date -d "${overdue_pattern}" +%m)
shadow_clean

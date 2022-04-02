## jd cookie
export JD_COOKIE=''

## TG_bot 通知参数，其他渠道通知变量参数参照 https://github.com/ffuqiangg/JD_Shell/blob/main/ENV.md
export TG_BOT_TOKEN=''
export TG_USER_ID=''

## 保留脚本运行日志天数
RmLogDaysAgo='7'

## 随机延迟最大值（秒），留空或为0则任务准时运行无延迟，如需设置最小延迟可自行添加 RandomMin 变量
RandomMax='300'

## 排除脚本(不添加任务cron)，填写完整脚本文件名(不带后缀)，多个脚本用空格隔开
no_cron_list=""

## 独立js脚本文件
OwnRawFile=(
  #https://raw.githubusercontent.com/Ariszy/Private-Script/master/JD/zy_xyzzh.js
)

# ============= 长期活动变量 =============
## 宠汪汪积分有就换
export JOY_GET20WHEN16='true'
## 东东超市蓝币兑换
export MARKET_COIN_TO_BEANS='超值'
## 摇钱树卖出金币
export MONEY_TREE_SELL_FRUIT='false'
## 东东农场水滴换豆
export FRUIT_BEAN_CARD='false'

# ============= 短期活动变量 ==============

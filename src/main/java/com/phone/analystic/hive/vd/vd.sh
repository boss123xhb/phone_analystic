#!/bin/bash

##### ./vd.sh  -d 2018-09-23

dt=''
#循环运行时所带的参数
until [ $# -eq 0 ]
do
if [ $1'x' = '-dx' ]
then
shift
dt=$1
fi
shift
done

month=
day=
#判断日期是否合法和正常
if [ ${#dt} = 10 ]
then
echo "dt:$dt"
else
dt=`date -d "1 days ago" "+%Y-%m-%d"`
fi

#计算month和day
month=`date -d "$dt" "+%m"`
day=`date -d "$dt" "+%d"`
echo "running date is:$dt,month is:$month,day is:$day"
echo "running hive SQL statment..."

#run hive hql
#用户去重个数 浏览器深度
hive --database phone -e "
set hive.exec.mode.local.auto=true;
set hive.groupby.skewindata=true;
from(
select
from_unixtime(cast(l.s_time/1000 as bigint),"yyyy-MM-dd") as dt,
l.pl as pl,
l.u_ud as uid,
(case
when count(l.p_url) = 1 then "pv1"
when count(l.p_url) = 2 then "pv2"
when count(l.p_url) = 3 then "pv3"
when count(l.p_url) = 4 then "pv4"
when  count(l.p_url) < 10 and count(l.p_url) >= 5 then "pv5_10"
when  count(l.p_url) < 30 and count(l.p_url) >= 10 then "pv10_30"
when  count(l.p_url) < 60 and count(l.p_url) >= 30 then "pv30_60"
else "pv60plus"
end) as pv
from phone l
where month=09
and day=22
and l.p_url <> null
and l.pl is not null
group by from_unixtime(cast(l.s_time/1000 as bigint),"yyyy-MM-dd"),l.pl,l.u_ud
) as tmp
insert overwrite table stats_view_depth_tmp
select dt,pl,pv,count(distinct uid) as ct
where uid is not null
group by dt,pl,pv
"

#用户去重个数 浏览器深度
hive --database phone -e "
set hive.exec.mode.local.auto=true;
set hive.groupby.skewindata=true;
with tmp as(
select dt,pl as pl,ct as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv1' union all
select dt,pl as pl,0 as pv1,ct as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv2' union all
select dt,pl as pl,0 as pv1,0 as pv2,ct as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv3' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,ct as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv4' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,ct as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv5_10' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,ct as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv10_30' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,ct as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv30_60' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,ct as pv60plus from stats_view_depth_tmp where col = 'pv60plus'
)
from tmp
insert overwrite table stats_view_depth
select phone_date(dt),phone_platform(pl),2,sum(pv1),sum(pv2),sum(pv3),sum(pv4),sum(pv5_10),sum(pv10_30),sum(pv30_60),sum(pv60plus),dt
group by dt,pl
"

#run hive hql again
#session去重个数---浏览器深度
hive --database phone -e "
set hive.exec.mode.local.auto=true;
set hive.groupby.skewindata=true;
from(
select
from_unixtime(cast(l.s_time/1000 as bigint),"yyyy-MM-dd") as dt,
l.pl as pl,
l.u_sd as usd,
(case
when count(l.p_url) = 1 then "pv1"
when count(l.p_url) = 2 then "pv2"
when count(l.p_url) = 3 then "pv3"
when count(l.p_url) = 4 then "pv4"
when  count(l.p_url) < 10 and count(l.p_url) >= 5 then "pv5_10"
when  count(l.p_url) < 30 and count(l.p_url) >= 10 then "pv10_30"
when  count(l.p_url) < 60 and count(l.p_url) >= 30 then "pv30_60"
else "pv60plus"
end) as pv
from phone l
where month=09
and day=22
and l.p_url <> null
and l.pl is not null
group by from_unixtime(cast(l.s_time/1000 as bigint),"yyyy-MM-dd"),l.pl,l.u_sd
) as tmp
insert overwrite table stats_view_depth_tmp
select dt,pl,pv,count(distinct usd) as ct
where usd is not null
group by dt,pl,pv
"

#session去重个数---浏览器深度
hive --database phone -e "
set hive.exec.mode.local.auto=true;
set hive.groupby.skewindata=true;
with tmp as(
select dt,pl as pl,ct as pv1,0 as pv2,0 as pv3,0 as 4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv1' union all
select dt,pl as pl,0 as pv1,ct as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv2' union all
select dt,pl as pl,0 as pv1,0 as pv2,ct as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv3' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,ct as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv4' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,ct as pv5_10,0 as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv5_10' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,ct as pv10_30,0 as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv10_30' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,ct as pv30_60,0 as pv60plus from stats_view_depth_tmp where col = 'pv30_60' union all
select dt,pl as pl,0 as pv1,0 as pv2,0 as pv3,0 as pv4,0 as pv5_10,0 as pv10_30,0 as pv30_60,ct as pv60plus from stats_view_depth_tmp where col = 'pv60plus'
)
from tmp
insert overwrite table stats_view_depth
select phone_date(dt),phone_platform(pl),1,sum(pv1),sum(pv2),sum(pv3),sum(pv4),sum(pv5_10),sum(pv10_30),sum(pv30_60),sum(pv60pluss),dt
group by dt,pl
"

#run sqoop statment
sqoop export --connect jdbc:mysql://hadoop03:3306/result \
--username root --password mysql \
--table stats_view_depth --export-dir hdfs://hadoop02:8020/hive/phone.db/stats_view_depth/* \
--input-fields-terminated-by "\\001" --update-mode allowinsert \
--update-key platform_dimension_id,date_dimension_id,kpi_dimension_id \
;

echo "the view depth job is fininshed."


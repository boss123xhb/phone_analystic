/**
 * Copyright (C), 2015-2018, XXX有限公司
 * FileName: NewUserMapper
 * Author:   14751
 * Date:     2018/9/19 21:25
 * Description:
 * History:
 * <author>          <time>          <version>          <desc>
 * 作者姓名           修改时间         版本号            描述
 */
package com.phone.analystic.mr.newuser;

import com.phone.analystic.modle.StatsCommonDimension;
import com.phone.analystic.modle.StatsUserDimension;
import com.phone.analystic.modle.base.BrowserDimension;
import com.phone.analystic.modle.base.DateDimension;
import com.phone.analystic.modle.base.KPIDimension;
import com.phone.analystic.modle.base.PlatformDimension;
import com.phone.analystic.modle.value.map.TimeOutPutValue;
import com.phone.common.DateEnum;
import com.phone.common.EventLogContant;
import com.phone.common.KpiType;
import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.log4j.Logger;

import java.io.IOException;

/**
 * 〈一句话功能简述〉<br> 
 * 〈NewUserMapper---mapper函数 简单的封装〉
 *
 * @author 14751
 * @create 2018/9/19 
 * @since 1.0.0
 * 用户模块下的新增用户
 *
 * 注意点：每次测试前都要清空数据库中的数据
 * 新建查询---执行所有的SQL语句
 * 如下：
truncate dimension_browser;
truncate dimension_currency_type;
truncate dimension_date;
truncate dimension_event;
truncate dimension_inbound;
truncate dimension_kpi;
truncate dimension_location;
truncate dimension_os;
truncate dimension_payment_type;
truncate dimension_platform;
truncate event_info;
truncate order_info;
truncate stats_device_browser;
truncate stats_device_location;
truncate stats_event;
truncate stats_hourly;
truncate stats_inbound;
truncate stats_order;
truncate stats_user;
truncate stats_view_depth;
 */
public class NewUserMapper extends Mapper<LongWritable,Text,StatsUserDimension,TimeOutPutValue> {
    private static final Logger logger = Logger.getLogger(NewUserMapper.class);
    private StatsUserDimension k = new StatsUserDimension();
    private TimeOutPutValue v = new TimeOutPutValue();

    private KPIDimension newUserKpi = new KPIDimension(KpiType.NEW_USER.kpiName);
    private KPIDimension newBrowserUserKpi = new KPIDimension(KpiType.BROWSER_NEW_USER.kpiName);

    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        String line = value.toString();
        if(StringUtils.isEmpty(line)){
            return ;
        }

        //拆分
        String[] fields = line.split("\u0001");
        //en是事件名称
        String en = fields[2];
        if(StringUtils.isNotEmpty(en) && en.equals(EventLogContant.EventEnum.LAUNCH.alias)){
            //获取想要的字段
            String serverTime = fields[1];
            String platform = fields[13];
            String uuid = fields[3];
            String browserName = fields[24];
            String browserVersion = fields[25];

            if(StringUtils.isEmpty(serverTime) || StringUtils.isEmpty(uuid)){
                logger.info("serverTime & uuid is null serverTime:"+serverTime+".uuid"+uuid);
                return;
            }

            //构造输出的key
            long stime = Long.valueOf(serverTime);
            PlatformDimension platformDimension = PlatformDimension.getInstnce(platform);
            DateDimension dateDimension = DateDimension.buildDate(stime, DateEnum.DAY);
            StatsCommonDimension statsCommonDimension = this.k.getStatsCommonDimension();
            //为StatsCommonDimension设值
            statsCommonDimension.setDateDimension(dateDimension);
            statsCommonDimension.setPlatformDimension(platformDimension);

            //用户模块新增用户
            //设置默认的浏览器对象(因为新增用户指标并不需要浏览器维度，所以赋值为空)
            BrowserDimension defaultBrowserDimension = new BrowserDimension("","");
            statsCommonDimension.setKpiDimension(newUserKpi);
            this.k.setBrowserDimension(defaultBrowserDimension);
            this.k.setStatsCommonDimension(statsCommonDimension);
            this.v.setId(uuid);
            context.write(this.k,this.v);//输出

            //浏览器模块新增用户
            statsCommonDimension.setKpiDimension(newBrowserUserKpi);
            BrowserDimension browserDimension = new BrowserDimension(browserName,browserVersion);
            this.k.setBrowserDimension(browserDimension);
            this.k.setStatsCommonDimension(statsCommonDimension);
            context.write(this.k,this.v);//输出
        }
    }
}
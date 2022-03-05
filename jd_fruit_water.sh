#!/usr/bin/env bash
shopt -s nullglob

water_num=$(sed -n '/^【今日共/p' /jd/log/jd_fruit/"$(date +%Y-%m-%d)"-18-*-*.log | awk -F '[】次]' '{print $2}')
if [[ $water_num -lt 42 ]]; then
    task jd_fruit
fi

exit 0

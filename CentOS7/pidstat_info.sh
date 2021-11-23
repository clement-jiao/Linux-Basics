#!/bin/bash
# date: 2021-05-30
# auther: xx@xx.com
 
top_line=10
 
 
function print_color_blue() {
    input_1="$*"; red=31; green=32; yellow=33; blue=34; white=37
    color=$blue
    printf "\033[4;${color}m${input_1}\033[0m\n"
}
sum_help=1
function print_function_name() {
    input_1=$1
    input_2=$2
    split_line="==================================="
    print_color_blue  "\n""["${sum_help}"]"$input_1""
    sum_help=$((${sum_help}+1))
}
cpu_info() {
    print_function_name $FUNCNAME
    pidstat -ul | grep PID | head -1
    pidstat -ul | sed "1,3d" | sort -k8nr | head -${top_line}
}
ram_info() {
    print_function_name $FUNCNAME
    pidstat -rl | grep PID | head -1
    pidstat -rl | sed "1,3d" | sort -k8nr | head -${top_line}
}
storage_info() {
    print_function_name $FUNCNAME
    format="%-23s%-15s%-10s%-10s%-10.1f%-20s%-10s\n"
    format_2="%-23s%-15s%-10s%-10s%-10s%-20s%-10s\n"
    echo time pid kB_rd/s kB_wr/s kB_ccwr/s KB_read_and_write  Command | awk '{printf("'"$format_2"'",$1,$2,$3,$4,$5,$6,$7)}'
    pidstat -dl | sed "1,3d" |awk '{rd_and_rw=$5+$6; printf("'"$format"'",$1,$4,$5,$6,$7,rd_and_rw,$8)}' | sort -k5nr| head -${top_line}
}
other_info() {
    print_function_name $FUNCNAME
    pidstat -u | grep PID
    pidstat -u | sed "1,3d" | sort -k8n | tail -${top_line}
}
 
print_function_name "script_change_log:  2021-05-30 release v1"
cpu_info
ram_info
storage_info
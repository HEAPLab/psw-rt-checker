#!/bin/bash

# read_proccgroup: prints out cgroup information given a pid
# $1: the pid to print
read_proccgroup(){
    for line in "$(cat /proc/$1/cgroup)"; do
        for cont in "$(cut -d':' -f2 <<< """$1""" | tr ',' ' ')"; do
            echo "$cont: $(get_cgroup_path "$cont" "$(cut -d':' -f3)")"
        done
    done
}

# get_cgroup_path: returns the absolute cgroup folder path
# $1: controller name
# $2: path read from a line in /proc/[pid]/cgroup
get_cgroup_path(){
    echo "/sys/fs/cgroup/$1/$2" | sed 's;/\+;/;g'
}

# translate_sched_class: converts scheduling class id to a human-readable name
# $1: id of the scheduling class
translate_sched_class(){
    if [ -n "$1" ]; then
        case "$1" in
            0)
                echo "CFS";;
            1)
                echo "FIFO";;
            2)
                echo "Round-Robin";;
            3)
                echo "Batch";;
            5)
                echo "Idle";;
            6)
                echo "Deadline";;
            *)
                echo "Unknown";;
        esac
    fi
}

# print_bold: prints the string in bold
# $1: string to print
print_desc(){
    printf '\033[1m%-25s\033[0m' "$1"
}

# print_description: prints the program description given a single pid
# $1: pid of the application
print_description(){
    if [ -n "$1" ]; then
        print_desc "Command line:"
        cat "/proc/$1/cmdline"
        echo ''
        print_desc "PID:"
        echo "$1"
        print_desc "User:"
        ps -p "$1" -o user --no-header
        print_desc "State:"
        grep '^State' "/proc/$1/status" | cut -f2-
        print_desc "Scheduling Policy:"
        translate_sched_class $(cut -d' ' -f41 "/proc/$1/stat")
        print_desc "Scheduling Priority:"
        cut -d' ' -f18 "/proc/$1/stat"
        #print_cgroups is here
        print_desc "CPUs allowed:"
        grep '^Cpus_allowed_list' "/proc/$1/status" | cut -f2
        print_desc "MEMs allowed:"
        grep '^Mems_allowed_list' "/proc/$1/status" | cut -f2
        #print_quotas is here
        print_desc "Nr. Context switches:"
        printf '%d (%d voluntary, %d involuntary)\n' $(grep '_switches' "/proc/$1/sched" | tr -d ' ' | cut -d':' -f2 | tr '\n' ' ')
        print_desc "Total Memory:"
        grep '^VmSize' "/proc/$1/status" | cut -f2 | sed 's/^ \+//g'
        print_desc "Locked Memory:"
        grep '^VmLck' "/proc/$1/status" | cut -f2 | sed 's/^ \+//g'
    fi
}

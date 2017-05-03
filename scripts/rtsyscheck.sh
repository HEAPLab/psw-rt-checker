#!/bin/bash

# Utility Printing Functions
# They will all do nothing if the input string is empty/not present

# print_line: prints line with prepending result box
# $1: text to print, won't print line if empty
print_line (){
    if [ -n "$1" ]; then
        echo -e "[      ] $1"
    fi
}


# print_result: overwrites the previous line with the result
print_result(){
    if [ -n "$1" ]; then
        local answer
        answer=$(get_return_message $1)
        echo -e "\e[1A\r[ $answer"
    fi
}

# print_lresult: combines the previous two functions in one
# $1: the line to be printed
# $2: the result number to use (check print_result for codes)
print_lineresult(){
    if [ -n "$2" ]; then
        local answer
        answer=$(get_return_message $2)
    fi
    if [ -n "$1" ]; then
        echo -e "[ $answer ] $1"
    fi
}

# Prints a line with ERROR prepended in red
print_error(){
    if [ -n "$1" ]; then
        >&2 echo -e "\e[91mError\e[0m: $1"
    fi
}

print_notice(){
    if [ -n "$1" ]; then
        echo -e "\e[34mNotice\e[0m: $1"
    fi
}

# get_return_message: gets the 4-char padded result message
# possible value are
#    0: OK
#    1: Caution
#    2: Warning
#    255: Not Present
get_return_message(){
    local answer
    if [ $1 -eq '0' ]; then
        #Everything went ok
        answer="\e[92m\e[1mGOOD\e[0m"
    elif [ $1 -eq '1' ]; then
        #We have to issue a warning
        answer="\e[93m\e[1mCAUT\e[0m"
    elif [ $1 -eq '2' ]; then
        #We have an Error
        answer="\e[91m\e[1mWARN\e[0m"
    elif [ $1 -eq '255' ]; then
        #The item was not present
        answer="\e[91m\e[1mNPRS\e[0m"
    fi
    echo $answer
}


# Utility Functions definitions

# check_variable_result: checks if the config variable is enabled
# if the variable is not present it is treated as not enabled
# $1: String to print
# $2: name of the config variable (prints nothing if empty)
# $3: result to print out if true
# $4: result to print out if false
# In case the variable is not found it will report as such
check_variable_result(){
    if [ -n "$1" ]; then
        local result_code
        local _rc
        if check_variable "$2"; then
            result_code=$3
            _rc=0
        else
            result_code=$4
            _rc=1
        fi
        print_lineresult "$1" $result_code
        return $_rc
    fi
}

# check_variable: returns 0 if the variable is set to y
# 1 otherwisei
# $1: name of the config variable
check_variable(){
    if [ -n "$1" ]; then
        config_val=$(get_variable_var "$1")
        if [ $? -eq 1 ]; then
            return 255
        fi
        if [ "$config_val" = "y" ]; then
            return 0
        else
            return 1
        fi
    else
        return 255
    fi
}

# get_variable_var: echoes the value for the specified kernel variable
# returns 1 if the variable is not present in the config
# $1: the name of the kernel variable
get_variable_var(){
    local config_line
    config_line=$(grep -e "$1=" <<< """$($config_cmd)""")
    if [ $? -eq 0 ]; then
        local config_params
        config_params=($( echo $config_line | tr '=' ' ' ))
        echo ${config_params[1]}
    else
        return 1
    fi
}

# get_config_cmd: generates the command needed to open the kernel config file
# (and removes all the comment line)
get_config_cmd(){
    if [ $(echo $config_path | grep "\w*.gz$") ]; then
        config_cmd="zcat $config_path"
    else
        config_cmd="cat $config_path"
    fi
}

# check_cmdline_result: checks if the specified string is in /proc/cmdline
# and prints the result
# $1: string to check
# $2: message to print
# $3: result if string is present
# $4: result if string is absent
check_cmdline_result(){
    if [ -n "$1" ]; then
        local rescode
        if check_cmdline "$1"; then
            rescode=$3
        else
            rescode=$4
        fi
        print_lineresult "$2" $rescode
    fi
}

# check_cmdline: checks if string is in /proc/cmdline
# returns 0 if the string is found, otherwise 1
# $1: string to check
check_cmdline(){
    if grep "$1" /proc/cmdline > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# get_cmdline_var: gets the value of the specified parameter in the commandline
# $1: variable to get
get_cmdline_var(){
    if [ -n "$1" ]; then
        echo $(cat /proc/cmdline | tr ' ' '\n' | grep "$1")
    fi
}

# Core function definitions

# find_config: returns the path to the kernel confi file
# Will return an empty string should it fail
find_config(){
    print_line "Checking config.gz presence"
    if [ -e /proc/config.gz ]; then
        config_path="/proc/config.gz"
        print_result 0
    elif [ -e /boot/config ]; then
        config_path="/boot/config"
        print_result 0
    elif [ -e "/boot/config-$(uname -r)" ]; then
        config_path="/boot/config-$(uname -r)"
        print_result 0
    else
        if [ -n $(find /lib/modules/$(uname -r) -type f \( -name "config.ko" -o \
                -name "config.o" \) 2>/dev/null ) ]; then
            # If we arrive here there is a config.ko or config.o file in the modules directory
            print_result 1
            echo -ne "We have detected the \e[1mconfig\e[0m module, would you like to load it with sudo? [y/N/use (s)u instead] "
            read answer
            case "$answer" in
                [yY][eE][sS]|[yY])
                    sudo modprobe config 2>/dev/null
                    if [ "$?" -eq 0 ]; then
                        print_line "Rechecking config presence"
                        if [ -e /proca/config.gz ]; then
                            config_path="/proc/config.gz"
                            print_result 0
                        else
                            print_result 2
                        fi
                    fi
                    ;;
                su|s)
                    su -c "modprobe config" 2>/dev/null
                    if [ "$?" -eq 0 ]; then
                        print_line "Rechecking config presence"
                        if [ -e /proc/config.gz ]; then
                            config_path="/proc/config.gz"
                            print_result 0
                        else
                            print_result 2
                        fi
                    fi
                    ;;
            esac
        else
            print_result 2
        fi
    fi
}

# check_config_vars: checks the kernel config for proper settings
check_config_vars(){
    echo "Checking for RT Preemption"
    check_variable_result "Checking if CONFIG_PREEMPT_RT_FULL is enabled" "CONFIG_PREEMPT_RT_FULL" 0 2
    check_variable_result "Checking if CONFIG_PREEMPT_RTB is disabled" "CONFIG_PREEMPT_RTB" 1 0
    check_variable_result "Checking if CONFIG_PREEMPT__LL is disabled" "CONFIG_PREEMPT__LL" 1 0
    check_variable_result "Checking if CONFIG_PREEMPT_VOLUNTARY is disabled" "CONFIG_PREEMPT_VOLUNTARY" 1 0
    check_variable_result "Checking if CONFIG_PREEMPT is disabled" "CONFIG_PREEMPT" 1 0
    check_variable_result "Checking if CONFIG_PREEMPT_NONE is disabled" "CONFIG_PREEMPT_NONE" 2 0
    if [ $? -eq 0 ]; then
        print_error "Non preemptible kernel"
    fi
    echo "Checking Interrupts"
    check_variable_result "Checking if CONFIG_GENERIC_IRQ_MIGRATION is enabled" "CONFIG_GENERIC_IRQ_MIGRATION" 0 1
    check_variable_result "Checking if CONFIG_IRQ_FORCED_THREADING is enabled" "CONFIG_IRQ_FORCED_THREADING"  0 2
    echo "Checking Tick Subsystem"
    check_variable_result "Checking if CONFIG_HZ_PERIODIC is disabled" "CONFIG_HZ_PERIODIC" 2 0
    check_variable_result "Checking if CONFIG_NO_HZ_IDLE is disabled" "CONFIG_HZ_IDLE" 1 0
    check_variable_result "Checking if CONFIG_NO_HZ_FULL is enabled" "CONFIG_HZ_FULL" 0 1
    check_variable "CONFIG_HZ_FULL_ALL"
    if [ $? -eq 0 ]; then
        print_notice "CONFIG_HZ_FULL_ALL is enabled"
    fi
    print_notice "CONFIG_HZ has value $(get_variable_var "CONFIG_HZ")"
    echo "Checking RCU Subsystem"
    check_variable_result "Checking if CONFIG_RCU_NOCB_CPU is enabled" "CONFIG_RCU_NOCB_CPU" 0 2
    check_variable_result "Checking if CONFIG_RCU_NOCB_CPU_NONE is disabled" "CONFIG_RCU_NOCB_CPU_NONE" 2 0
    check_variable_result "Checking if CONFIG_RCU_NOCB_CPU_ALL is enabled" "CONFIG_RCU_NOCB_CPU_ALL" 0 1
    check_variable_result "Checking if CONFIG_PREEMPT_RCU is enabled" "CONFIG_PREEMPT_RCU" 0 1
    echo "Checking Other configs"
    check_variable_result "Checking if CONFIG_HOTPLUG_CPU is enabled" "CONFIG_HOTPLUG_CPU" 0 1
    check_variable_result "Checking if CONFIG_HIGH_RES_TIMERS is enabled" "CONFIG_HIGH_RES_TIMERS" 0 2
    check_variable_result "Checking if CONFIG_PREEMPT_NOTIFIERS is enabled" "CONFIG_PREEMPT_NOTIFIERS" 0 2
}

check_cmd_line(){
    echo "Checking kernel command-line parameters"
    check_cmdline_result "quiet" "Checking for quiet boot" 0 1
    if check_cmdline "isolcpus"; then
        print_notice "$(get_cmdline_var "isolcpus")"
    else
        print_lineresult "isolcpu not specified in the kernel command parameters" 1
    fi
    if check_cmdline "nohz_full"; then
        print_notice "$(get_cmdline_var "nohz_full")"
    else
        if ! check_variable "CONFIG_NO_HZ_FULL"; then
            print_lineresult "nohz_full not present and NO_HZ_FULL disabled" 1
        fi
    fi
    if check_cmdline "rcu_nocbs"; then
        print_notice "$(get_cmdline_var "rcu_nocbs")"
    else
        if ! check_variable "CONFIG_RCU_NOCB_CPU_ALL"; then
            print_lineresult "rcu_nocbs not present and RCU_NOCB_CPU_ALL disabled" 1
        fi
    fi
}

# Main

find_config

if [ -n "$config_path" ]; then
    echo "Using config from $config_path"
    get_config_cmd
    check_config_vars
    check_cmd_line
else
    echo "config not found, skipping kernel compilation flags checks"
fi

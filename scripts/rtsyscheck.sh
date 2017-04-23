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
        >2& echo -e "\e[91mError\e[0m: $1"
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
        answer="\e[91m\e[1m NP \e[0m"
    fi
    echo $answer
}


# Utility Functions definitions

# get_config_cmd: generates the command needed to open the kernel config file
# (and removes all the comment line)
get_config_cmd(){
    if [ $(echo $config_path | grep "\w*.gz$") ]; then
        config_cmd="zcat $config_path"
    else
        config_cmd="cat $config_path"
    fi
    config_cmd="$config_cmd | grep -v '^#'"
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


# Main

find_config

if [ -n "$config_path" ]; then
    echo "Using config from $config_path"
    get_config_cmd
else
    echo "config not found, skipping kernel compilation flags checks"
fi

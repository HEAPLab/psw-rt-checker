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
        echo -e "\e[1A\r[$text"
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

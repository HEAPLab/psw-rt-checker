#!/bin/bash

# Utility Printing Functions
# They will all do nothing if the input string is empty/not present

# print_line: prints line with prepending result box
print_line (){
    if [ -n "$1" ]; then
        echo -e "[      ] $1"
    fi
}


# print_result: overwrites the previous line with the result
print_result(){
    if [ -n "$1" ]; then
        local text=""
        if [ $1 -eq '0' ]; then
            #Everything went ok
            text="\e[92m\e[1mGOOD\e[0m"
        elif [ $1 -eq '1' ]; then
            #We have to issue a warning
            text="\e[93m\e[1mCAUT\e[0m"
        elif [ $1 -eq '2' ]; then
            #We have an Error
            text="\e[91m\e[1mWARN\e[0m"
        fi
        echo -e "\e[1A\r[ $text"
    fi
}

# print_lresult: combines the previous two functions in one
print_lresult(){
    print_line $1
    print_result $2
}

# Prints a line with ERROR prepended in red
print_error(){
    if [ -n "$1" ]; then
        >2& echo -e "\e[91mError\e[0m: $1"
    fi
}

#!/bin/bash
tput civis


CLEAR_LINE="\e[2K"

SPINNER_CHARS="⠇⠋⠙⠞⠗⠟⠈⠙"


function show_spinner() {
  task_name=$1
  status_message=$2
  while :; do
    jobs %1 > /dev/null 2>&1
    [ $? = 0 ] || {
      printf "${CLEAR_LINE}✓ ${task_name} Completed\n"
      break
    }
    for (( i=0; i<${#SPINNER_CHARS}; i++ )); do
      sleep 0.05
      printf "${CLEAR_LINE}${SPINNER_CHARS:$i:1} ${task_name} ${status_message}\r"
    done
  done
}


bash <(curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh)


read -p "Enter the command to execute: " user_command
status_message="${2-Processing...}"
task_name="${3-$user_command}"


$user_command & show_spinner "$task_name" "$status_message"

tput cnorm

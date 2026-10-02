#!/bin/bash

set -x

# Example: Checking a string input
read -p "Enter 'yes' or 'no': " answer

if [[ "$answer" == "yes" ]]; then
    echo "You selected yes"
elif [[ "$answer" == "no" ]]; then
    echo "You selected no"
else
    echo "Invalid input"
fi

# Checks for errors encountered
if [ $? -ne 0 ]; then
    echo "Error occurred."
fi

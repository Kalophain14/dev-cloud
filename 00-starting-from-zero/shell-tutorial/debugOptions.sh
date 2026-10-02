# Debug and Troubleshooting
#
#
#!/bin/bash

# Print each command
set -x


# Check the exit code
if [ $? -ne 0 ]; then
    echo "Error occurred."
fi


# echo statements
echo "Value of variable x is: $x"


# Exit immediately if there is an Error / Fails
set -e

# Use cronlogs for scheduled jobs

/var/log/syslog

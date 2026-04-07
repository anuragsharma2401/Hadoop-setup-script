#!/bin/bash

set -e
set -o pipefail
trap 'echo "Error at Line $LINENO: $BASH_COMMAND failed. Fix and return."; exit 1' ERR

if [ "$EUID" -ne 0 ]; then
   echo "Please run this script by a sudo user."
   exit 1 
fi

if command -v pig >/dev/null 2>&1 && pig -version >/dev/null 2>&1; then
    echo "Pig is already installed and working."
    pig -version
    exit 0
fi    

su - hduser <<'EOF'

if [ ! -f "pig-0.16.0.tar.gz" ]; then
    echo "Downloading Pig..."
    wget https://dlcdn.apache.org/pig/pig-0.16.0/pig-0.16.0.tar.gz
fi

if [ ! -d "pig-0.16.0" ]; then
    echo "Extracting Pig..."
    tar -xzf pig-0.16.0.tar.gz
    
    rm pig-0.16.0.tar.gz
fi

if [ -d "pig-0.16.0" ]; then
    mkdir -p /usr/local/pignew
    echo "Moving Pig to /usr/local/pignew..."
    mv pig-0.16.0/* /usr/local/pignew
    
else
    echo "Pig directory not found after extraction. Exiting..."
    exit 1
fi

# Check if the Pig section is already in the .bashrc file
if grep -q '#PIG VARIABLES' /home/hduser/.bashrc; then
    echo "Pig environment variables are already present in .bashrc."
else 
    # If the marker is not found, append the Pig variables to the .bashrc file
    echo "Appending Pig environment variables to .bashrc..."
    cat <<EOL >> /home/hduser/.bashrc
#PIG VARIABLES
export PIG_HOME=/usr/local/pignew
export PATH=\$PATH:\$PIG_HOME/bin
export PIG_CLASSPATH=\$PIG_HOME/conf:\$HADOOP_INSTALL/etc/hadoop/bin
export PIG_CONF_DIR=\$PIG_HOME/conf
export PIG_CLASSPATH=\$PIG_CONF_DIR
#PIG VARIABLES END
EOL
    echo ".bashrc file updated successfully."
fi

# Verify if the .bashrc file has been updated successfully
echo "Verifying the update..."
if grep -q '#PIG VARIABLES' /home/hduser/.bashrc; then
    echo "Pig environment variables are set in .bashrc."
else
    echo "Pig environment variables were not added to .bashrc. Exiting..."
    exit 1
fi

echo "Run: source ~/.bashrc"

pig -version

EOF

echo "Pig installed and setup successfully..."
echo ""

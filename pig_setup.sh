#!/bin/bash

set -e
set -o pipefail
trap 'echo "Error at Line $LINENO. Fix and return."; exit 1' ERR

if [ "$EUID" -ne 0 ]; then
   echo "Please run this script by a sudo user."
   exit 1 
fi

mkdir -p /usr/local/pignew
chown -R hduser:hadoop /usr/local/pignew

su - hduser <<'EOF'

if [ -x /usr/local/pignew/bin/pig ]; then
    echo "Pig binary found at /usr/local/pignew/bin/pig"
    if command -v /usr/local/pignew/bin/pig >/dev/null 2>&1 || /usr/local/pignew/bin/pig -version >/dev/null 2>&1; then
        echo "Pig is already installed and working."
        exit 0
    else 
        echo "Pig binaries exists but failed to run. Checking environment variables..."
    fi
fi    

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
    echo "Moving Pig to /usr/local/pignew..."
    mv pig-0.16.0/* /usr/local/pignew
    rmdir pig-0.16.0
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

source ~/.bashrc

EOF

echo "=========================================="
echo "     Pig Setup Completed Successfully     "
echo "=========================================="
echo ""

echo "Next Steps:"
echo "1. Switch to hduser:"
echo "   su - hduser"
echo ""
echo "2. (If Hadoop is not running) start Hadoop:"
echo "   start-dfs.sh"
echo "   start-yarn.sh"
echo ""
echo "3. Run Pig:"
echo "   pig"
echo ""
echo "=========================================="

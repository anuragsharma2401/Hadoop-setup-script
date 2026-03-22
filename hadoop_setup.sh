#!/bin/bash

set -e
set -o pipefail
trap 'echo "Error at Line $LINENO. Fix and return."; exit 1' ERR

if [ "$EUID" -ne 0 ]; then
   echo "Please run this script by a sudo user."
   exit 1 
fi

HADOOP_VERSION=3.4.1
HADOOP_HOME=/usr/local/hadoop
HADOOP_USER=hduser


if command -v java >/dev/null 2>&1; then
    #INSTALLED_VERSION=$(java -version 2>&1 | awk -F[\".] '/version/ {print $2}')
    INSTALLED_VERSION=$(java -version 2>&1 | java -version 2>&1 | grep "11")
else
    INSTALLED_VERSION=0
fi

if [ "$INSTALLED_VERSION" -eq 11 ]; then
    echo "Java 11 is already installed."
else
    echo "Installing Java 11..."
    apt update
    apt install -y openjdk-11-jdk 
fi 

echo "Setting Java 11 as the default version..."
sudo update-alternatives --set java /usr/lib/jvm/java-11-openjdk-amd64/bin/java

# Display the installed Java version
echo "Java Version: "
java -version

echo "Creating Hadoop group and user...."

if ! getent group hadoop > /dev/null; then
    groupadd hadoop
fi

if ! id "$HADOOP_USER" &>/dev/null; then
    useradd -m -g hadoop -s /bin/bash $HADOOP_USER || { echo "Failed to create user $HADOOP_USER"; exit 1; }
    echo "$HADOOP_USER:123" | chpasswd || { echo "Failed to set password for $HADOOP_USER"; exit 1; }
    echo "User created. Default password: 123. You can change it after..."
fi

usermod -aG sudo $HADOOP_USER

echo "Installing SSH....."
if ! apt-get install -y ssh; then
    echo "Failed to install openssh-server. Exiting..."
    exit 1
fi

echo "Setting up passwordless SSH for $HADOOP_USER...."
su - $HADOOP_USER -c '

mkdir -p /home/hduser/.ssh

if [ ! -f ~/.ssh/id_rsa ]; then 
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
else
    rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
fi

# Append the public key to authorized_keys for passwordless login
cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys
if [ $? -eq 0 ]; then
    echo "cat pub completed successfully."
else
    echo "cat pub failed."
    exit 1
fi

# Ensure the correct permissions for SSH files
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
'

if [ -n /usr/local/hadoop ] && [ -d /usr/local/hadoop ]; then
    rm -rf /usr/local/hadoop
fi

# Ensure HADOOP_HOME directory exists
if [ ! -d /usr/local/hadoop ]; then
    echo "Creating HADOOP_HOME directory..."
    mkdir -p /usr/local/hadoop
    if [ $? -ne 0 ]; then
        echo "Failed to create HADOOP_HOME directory. Exiting..."
        exit 1
    fi
    # Set proper ownership and permissions
    echo "Setting ownership and permissions..."
    chown -R hduser:hadoop /usr/local/hadoop
    if [ $? -ne 0 ]; then
    echo "Failed to set ownership. Exiting..."
    exit 1
    fi
fi

chmod -R 755 /usr/local/hadoop
if [ $? -ne 0 ]; then
    echo "Failed to set permissions. Exiting..."
    exit 1
fi

# Create necessary HDFS directories
echo "Creating HDFS directories..."
mkdir -p /usr/local/hadoop_store/hdfs/namenode
mkdir -p /usr/local/hadoop_store/hdfs/datanode

if [ $? -ne 0 ]; then
    echo "Failed to create HDFS directories. Exiting..."
    exit 1
fi

# Set ownership and permissions for Hadoop data directories
echo "Setting permissions for HDFS directories..."
chown -R hduser:hadoop /usr/local/hadoop_store
if [ $? -ne 0 ]; then
    echo "Failed to set permissions for HDFS directories. Exiting..."
    exit 1
fi

chmod -R 750 /usr/local/hadoop_store
if [ $? -ne 0 ]; then
    echo "Failed to set permissions for HDFS directories. Exiting..."
    exit 1
fi

mkdir -p /app/hadoop/tmp

chown -R hduser:hadoop /app

chmod -R 750 /app

su - $HADOOP_USER <<'EOF'

# Test SSH connection to localhost using the Hadoop user
echo "Testing SSH connection..."
#ssh -o StrictHostKeyChecking=no localhost
ssh localhost
if [ $? -eq 0 ]; then
    echo "SSH setup completed successfully."
else
    echo "SSH setup failed."
    exit 1
fi

if [ ! -f "hadoop-3.4.1.tar.gz" ]; then
    echo "Downloading Hadoop..."
    wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
    if [ $? -ne 0 ]; then
        echo "Download failed. Exiting..."
        exit 1
    fi
fi

if [ -f "hadoop-3.4.1.tar.gz" ]; then
    echo "Extracting Hadoop..."
    tar -xzf hadoop-3.4.1.tar.gz
    if [ $? -ne 0 ]; then
        echo "Extraction failed. Exiting..."
        exit 1
    fi
   #rm hadoop-3.4.1.tar.gz
fi

#*****

# Move extracted Hadoop to HADOOP_HOME
if [ -d "hadoop-3.4.1" ]; then
    echo "Moving Hadoop to HADOOP_HOME..."
    mv hadoop-3.4.1/* /usr/local/hadoop
    if [ $? -ne 0 ]; then
        echo "Failed to move Hadoop to HADOOP_HOME. Exiting..."
        exit 1
    fi
else
    echo "Hadoop directory not found after extraction. Exiting..."
    exit 1
fi







#BASH_FILE="/home/hduser/.bashrc"
#echo "Target: $BASH_FILE"
# Check if the Hadoop section is already in the .bashrc file
if grep -qxF '#HADOOP VARIABLES START' /home/hduser/.bashrc; then
    echo "Hadoop environment variables are already present in .bashrc."
else 
    # If the marker is not found, append the Hadoop variables to the .bashrc file
    echo "Appending Hadoop environment variables to .bashrc..."
    cat <<EOL >> /home/hduser/.bashrc
#HADOOP VARIABLES START
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_INSTALL=/usr/local/hadoop
export PATH=\$PATH:\$HADOOP_INSTALL/bin
export PATH=\$PATH:\$HADOOP_INSTALL/sbin
export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_HOME=\$HADOOP_INSTALL
export HADOOP_HDFS_HOME=\$HADOOP_INSTALL
export YARN_HOME=\$HADOOP_INSTALL
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_INSTALL/lib/native
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_INSTALL/lib"
#HADOOP VARIABLES END
EOL
    if [ $? -eq 0 ]; then
        echo ".bashrc file updated successfully."
    else
        echo "Failed to update .bashrc. Exiting..."
        exit 1
    fi
fi

# Verify if the .bashrc file has been updated successfully
echo "Verifying the update..."
if grep -qxF '#HADOOP VARIABLES START' /home/hduser/.bashrc; then
    echo "Hadoop environment variables are set in .bashrc."
else
    echo "Hadoop environment variables were not added to .bashrc. Exiting..."
    exit 1
fi

echo "Setting JAVA_HOME in hadoop-env.sh..."

HADOOP_ENV="/usr/local/hadoop/etc/hadoop/hadoop-env.sh"
JAVA_PATH="/usr/lib/jvm/java-11-openjdk-amd64"

if grep -q "^export JAVA_HOME" /usr/local/hadoop/etc/hadoop/hadoop-env.sh; then
    echo "JAVA_HOME exists. Updating..."
    sed -i "s|^export JAVA_HOME.*|export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64|" "/usr/local/hadoop/etc/hadoop/hadoop-env.sh"
else
    echo "JAVA_HOME not found. Adding..."
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> "/usr/local/hadoop/etc/hadoop/hadoop-env.sh"
fi



cat <<EOL > "/usr/local/hadoop/etc/hadoop/core-site.xml" 
<?xml version="1.0"?>
<configuration>
 <property>
  <name>hadoop.tmp.dir</name>
  <value>/app/hadoop/tmp</value>
  <description>A base for other temporary directories.</description>
 </property>

 <property>
  <name>fs.defaultFS</name>
  <value>hdfs://localhost:9000</value>
  <description>The name of the default file system.  A URI whose
  scheme and authority determine the FileSystem implementation.  The
  uri's scheme determines the config property (fs.SCHEME.impl) naming
  the FileSystem implementation class.  The uri's authority is used to
  determine the host, port, etc. for a filesystem.</description>
 </property>
</configuration>

EOL

cat <<EOL > "/usr/local/hadoop/etc/hadoop/mapred-site.xml" 
<?xml version="1.0"?>
<configuration>
 <property>
  <name>mapreduce.framework.name</name>
  <value>yarn</value>
 </property>
</configuration>

EOL

cat  <<EOL > "/usr/local/hadoop/etc/hadoop/yarn-site.xml"
<?xml version="1.0"?>
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>localhost</value>
  </property>

  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>

EOL

cat <<EOL > "/usr/local/hadoop/etc/hadoop/hdfs-site.xml" 
<?xml version="1.0"?>
<configuration>
 <property>
  <name>dfs.replication</name>
  <value>1</value>
  <description>Default block replication.
  The actual number of replications can be specified when the file is created.
  The default is used if replication is not specified in create time.
  </description>
 </property>
<property>
   <name>dfs.block.size</name>
   <value>1048576</value>
 </property>
 <property>
   <name>dfs.namenode.name.dir</name>
   <value>file:/usr/local/hadoop_store/hdfs/namenode</value>
 </property>
 <property>
   <name>dfs.datanode.data.dir</name>
   <value>file:/usr/local/hadoop_store/hdfs/datanode</value>
 </property>
</configuration>

EOL

EOF

if [ ! -d "/usr/local/hadoop_store/hdfs/namenode/current" ]; then
    su - $HADOOP_USER -c "$HADOOP_HOME/bin/hdfs namenode -format"
else
    echo "Namenode already formatted. Skipping."
fi











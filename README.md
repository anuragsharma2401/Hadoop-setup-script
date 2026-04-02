# 🐘 Hadoop 3.4.1 One-Click Setup

This script automates the installation and configuration of **Apache Hadoop 3.4.1** in Single-Node (Pseudo-Distributed) mode on Ubuntu/Debian.

## 🚀 Features
- **Java 11 Auto-Install:** Detects and configures the correct OpenJDK version.
- **User Management:** Creates a dedicated `hduser` with optimized permissions.
- **SSH Automation:** Automatically generates RSA keys and enables passwordless login to localhost.
- **HDFS Configuration:** Sets up Namenode, Datanode, and Temp directories with proper ownership.
- **Environment Automation:** Modifies `.bashrc` and `hadoop-env.sh` automatically.

## 🛠️ Prerequisites
- Ubuntu 20.04 or 22.04 (recommended).
- Minimum 2GB RAM.
- `sudo` privileges.

## 📥 Installation
You can run this script directly from GitHub or download it manually:

```bash
wget https://github.com/anuragsharma2401/Hadoop-setup-script.git
chmod +x hadoop_setup.sh
sudo ./hadoop_setup.sh

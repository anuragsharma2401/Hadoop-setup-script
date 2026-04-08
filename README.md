# 🐘 Hadoop 3.4.1 + 🐷 Apache Pig One-Click Setup

This project automates the installation and configuration of:

- **Apache Hadoop 3.4.1**
- **Apache Pig 0.16.0**

in Single-Node (Pseudo-Distributed) mode on Ubuntu/Debian.

---

## 🚀 Features

### 🐘 Hadoop Setup (`hadoop_setup.sh`)
- **Java 11 Auto-Install:** Detects and configures the correct OpenJDK version.
- **User Management:** Creates a dedicated `hduser` with optimized permissions.
- **SSH Automation:** Automatically generates RSA keys and enables passwordless login to localhost.
- **HDFS Configuration:** Sets up Namenode, Datanode, and Temp directories with proper ownership.
- **Environment Automation:** Modifies `.bashrc` and `hadoop-env.sh` automatically.

---

### 🐷 Pig Setup (`pig_setup.sh`)
- **Automated Download & Install:** Downloads Apache Pig 0.16.0 and installs it in `/usr/local/pignew`.
- **Environment Automation:** Automatically updates `.bashrc` with required Pig environment variables.
- **Seamless Hadoop Integration:** Configures Pig to work smoothly with existing Hadoop setup.
- **User-Based Deployment:** Installs Pig under the `hduser` environment for Hadoop compatibility.
- **Safe Re-run Support:** Prevents duplicate environment entries using marker-based checks.

---

## 🛠️ Prerequisites

- Ubuntu 20.04 or 22.04 (recommended)
- Minimum **2GB RAM**
- `sudo` privileges

---

## 📥 Installation

The scripts can be downloaded manually or executed directly using raw GitHub links.

### Setup Hadoop

```bash
wget https://raw.githubusercontent.com/anuragsharma2401/Hadoop-setup-script/refs/heads/main/hadoop_setup.sh
chmod +x hadoop_setup.sh
sudo ./hadoop_setup.sh
```

### Setup Apache Pig 

```bash
wget https://raw.githubusercontent.com/anuragsharma2401/Hadoop-setup-script/refs/heads/main/pig_setup.sh
chmod +x pig_setup.sh
sudo ./pig_setup.sh

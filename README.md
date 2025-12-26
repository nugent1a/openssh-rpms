# OpenSSH RPM Builder (Universal)

![Version](https://img.shields.io/badge/Version-v32.0-brightgreen) ![Platform](https://img.shields.io/badge/Platform-RHEL%20%7C%20CentOS%20%7C%20Anolis%20%7C%20Kylin%20%7C%20openEuler-blue) ![Shell](https://img.shields.io/badge/Language-Bash-orange)

> **一键构建、智能探测、全平台兼容。** > 为您的 Linux 服务器轻松构建最新版本的 OpenSSH RPM 安装包。

---

## 📖 项目简介

本项目旨在为广大运维人员提供一个高度自动化、智能化的 OpenSSH 编译打包方案。脚本能够精准识别主流红帽系及其衍生发行版，自动处理复杂的依赖关系与 `SPEC` 配置，实现从源码到 RPM 安装包的一键转换。

脚本已针对国产化信创环境进行了深度优化，是您升级服务器安全组件的理想工具。

## ✨ 核心特性

* **🧠 智能探测 (Smart Mode)**：
    * 自动识别当前目录下的 `OpenSSH`、`OpenSSL` 及可选的 `Askpass` 源码包。
    * 动态提取文件名中的版本号，无需手动修改脚本配置。
* **🌍 全平台兼容 (Universal OS)**：
    * 支持 **RHEL/CentOS** (7/8/9)、**Fedora**、**Amazon Linux**。
    * 原生支持国产信创系统：**Anolis (龙蜥)**、**openEuler (欧拉)**、**Kylin (麒麟 V10)**、**UOS (统信 Server)**。
* **🎨 UI 交互设计**：
    * 标签像素级物理对齐，视觉清爽。
    * 构建日志路径清晰可见，方便回溯。
* **⚡ 极速模式 (Turbo Mode)**：
    * 在编译阶段尝试按下 `Ctrl+C`？脚本会触发“注入氮气”并伴随“核心熔毁”的趣味彩蛋逻辑。
* **🛡️ 安全集成**：
    * 自动集成 `PermitRootLogin yes` 与标准 PAM 配置。
    * 编译完成后自动清理 `/root/rpmbuild` 等临时构建目录。

## 🚀 快速开始

### 1. 准备源码环境
将本脚本与所需的源码包（格式通常为 `.tar.gz`）放置在同一目录下。

**必需文件示例：**
* `openssh-10.2p1.tar.gz`
* `openssl-3.3.1.tar.gz`

### 2. 运行脚本
赋予执行权限并启动：

```bash
chmod +x build_openssh.sh
./build_openssh.sh
```

### 2. 自动化流程
依赖检查：脚本会询问是否安装 yum 依赖，建议在首次运行时选择 [1] 安装。

静默构建：脚本将自动探测系统版本并开始编译，您可以在界面实时查看各步骤耗时。

获取产物：构建成功后，所有 RPM 包将输出至 /opt 目录下的压缩包中。

## 🖥️ 运行预览
<img width="1077" height="825" alt="image" src="https://github.com/user-attachments/assets/d7127331-f485-46a3-8598-6b60c6624267" />

## 安装(以CentOS7为例）

 从 [Release](https://github.com/nugent1a/OpenSSH-rpms/releases) 下载合适的版本

```bash
#解压
tar zxvf openssh-10.2p1-rpms-el7-x64.tar.gz
#卸载旧版本
yum remove openssh* -y
#安装新版本
yum install -y openssh-10.2p1-rpms-el7-x64/openssh-*
#重启sshd服务
systemctl restart sshd
```

不要关闭旧的SSH窗口，新开一个SSH，能打开，平稳落地


## 使用

安装完成后，您可以使用以下命令启动 OpenSSH 服务：
```bash
systemctl start sshd
systemctl enable sshd
```

# 免责声明

本项目提供的 OpenSSH RPM 包仅供学习和研究使用。生产环境使用本项目中的任何内容进行实际操作时，请务必谨慎，并自行承担相关风险。

1. **生产环境警示**：OpenSSH 升级涉及系统关键组件的更改，可能会导致系统不稳定或服务中断。在进行升级前，请确保已备份所有重要数据，并在测试环境中充分验证升级过程。

2. **备用连接建议**：升级过程中，建议保持现有的 SSH 会话不要断开，或开启 Telnet 等备用远程连接手段。

3. **责任与声明**：作者不对因使用本脚本导致的任何连接中断、系统损坏或数据丢失承担责任。用户在使用本项目时，应自行评估相关风险，并对自己的操作负责。

4. **支持与维护**：本项目为开源项目，维护者和贡献者将尽力提供支持和更新，但不保证项目的持续维护和问题修复。用户在使用过程中遇到问题，可以通过提交 issue 或 pull request 的方式与维护者进行交流。

通过使用本项目，您即表示已阅读并同意上述免责声明条款。如果您不同意这些条款，请勿使用本项目。

感谢您的理解与支持！


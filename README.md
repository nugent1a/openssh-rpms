# OpenSSH-rpms

本项目旨在升级适用于 CentOS 的 OpenSSH 包。通过此项目，您可以轻松地安装最新版本的 OpenSSH。

OpenSSH 是一个免费的 SSH 连接工具，广泛用于安全的远程登录和文件传输。本项目提供了RPM包的形式对OpenSSH进行升级，以确保您使用的是最新版本。

## 特性

- 升级到最新版本的 OpenSSH
- 提供 RPM 包
- 支持 CentOS 系统

## 安装

没什么好说的，升级完成以后执行
```bash
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
chmod 600 /etc/ssh/ssh_host_*_key
systemctl restart sshd
```

## 使用

安装完成后，您可以使用以下命令启动 OpenSSH 服务：
```bash
sudo systemctl start sshd
sudo systemctl enable sshd
```

# 免责声明

本项目提供的 OpenSSH RPM 包仅供学习和研究使用。生产环境使用本项目中的任何内容进行实际操作时，请务必谨慎，并自行承担相关风险。

1. **风险提示**：OpenSSH 升级涉及系统关键组件的更改，可能会导致系统不稳定或服务中断。在进行升级前，请确保已备份所有重要数据，并在测试环境中充分验证升级过程。

2. **责任声明**：本项目的维护者和贡献者不对因使用本项目内容而导致的任何直接或间接损失负责。用户在使用本项目时，应自行评估相关风险，并对自己的操作负责。

3. **支持与维护**：本项目为开源项目，维护者和贡献者将尽力提供支持和更新，但不保证项目的持续维护和问题修复。用户在使用过程中遇到问题，可以通过提交 issue 或 pull request 的方式与维护者进行交流。

4. **法律合规**：用户在使用本项目时，应遵守所在国家和地区的法律法规。任何因违反法律法规而导致的后果，由用户自行承担。

通过使用本项目，您即表示已阅读并同意上述免责声明条款。如果您不同意这些条款，请勿使用本项目。

感谢您的理解与支持！

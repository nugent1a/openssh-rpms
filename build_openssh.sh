#!/bin/bash

# ================= 配置区域 =================
# 脚本元数据 (显示在标题栏)
SCRIPT_AUTHOR="nugent1a"
SCRIPT_VERSION="v2.0"

# RPM 版本号
RPM_RELEASE="1"
# ===========================================

# 目录设置
BASE_DIR=$(pwd)
RPMBUILD_DIR="/root/rpmbuild"
OUTPUT_DIR="/opt"
LOG_DIR="/tmp/openssh_build_logs"

mkdir -p $LOG_DIR
tput civis # 隐藏光标

# === 1. 标准退出 ===
function cleanup_standard {
    tput cnorm
    echo -e "" 
    if [ -n "$(jobs -p)" ]; then
        echo -ne "\033[1;33m[INFO]\033[0m 正在终止后台任务... "
        kill $(jobs -p) >/dev/null 2>&1
        wait $(jobs -p) >/dev/null 2>&1
        echo -e "\033[1;32m[DONE]\033[0m"
    fi
    echo -e "\033[1;31m[EXIT]\033[0m 用户取消，已退出。"
    exit 1
}

# === 2. 加速彩蛋退出 ===
function cleanup_turbo {
    tput cnorm
    echo -e ""
    echo -ne "\033[1;36m[TURBO]\033[0m \033[1;33m收到加速指令，正在注入氮气\033[0m"
    for i in {1..5}; do echo -ne "\033[1;33m.\033[0m"; sleep 0.4; done
    if [ -n "$(jobs -p)" ]; then
        kill $(jobs -p) >/dev/null 2>&1
        wait $(jobs -p) >/dev/null 2>&1
    fi
    echo -e " \033[1;31m[FAILED]\033[0m"
    echo -e "\033[1;31m[CRASH] 警告：编译速度过快导致 CPU 核心熔毁，操作已强制中止。\033[0m"
    exit 1
}

trap cleanup_standard INT TERM

function error_exit {
    tput cnorm
    echo -e "\n❌ \033[1;31m严重错误:\033[0m $1"
    echo -e "📝 \033[1;33m错误日志:\033[0m ${LOG_DIR}"
    exit 1
}

# === 系统探测 ===
function get_os_tag {
    local dist=$(rpm --eval '%{?dist}' 2>/dev/null | tr -d '.')
    if [[ -n "$dist" ]] && [[ "$dist" != "%{?dist}" ]]; then 
        echo "$dist"
        return
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        local major="${VERSION_ID%%.*}"
        case "$ID" in
            centos|rhel|almalinux|rocky|scientific|eurolinux|circle|ol|oracle|cloudlinux)
                echo "el${major}"; return ;;
            fedora)
                echo "fc${major}"; return ;;
            amzn)
                if [[ "$major" == "2" ]]; then echo "amzn2"; elif [[ "$major" == "2023" ]]; then echo "amzn2023"; else echo "el7"; fi; return ;;
            anolis)
                echo "an${major}"; return ;;
            openEuler|openeuler)
                echo "oe${major}"; return ;;
            kylin|kylin_linux_advanced_server)
                echo "ky10"; return ;;
            uos)
                if [[ "$major" == "20" ]]; then echo "uos20"; else echo "uos${major}"; fi; return ;;
            alinux)
                echo "ali${major}"; return ;;
            tencentos)
                echo "tos${major}"; return ;;
            mageia)
                echo "mga${major}"; return ;;
        esac
    fi
    
    tput cnorm
    echo -e "\n\033[1;31m[ERROR] 无法识别当前操作系统发行版！\033[0m"
    exit 1
}

function get_arch {
    [ "$(uname -m)" == "x86_64" ] && echo "x64" || echo "arm64"
}

# === 源码探测 ===
function detect_source_files {
    ssh_files=(openssh-*.tar.gz)
    [ ! -e "${ssh_files[0]}" ] && error_exit "未找到 openssh-*.tar.gz"
    if [ ${#ssh_files[@]} -eq 1 ]; then
        SSH_TAR="${ssh_files[0]}"
    else
        tput cnorm
        echo -e "\033[1;33m[?] 请选择 OpenSSH 版本:\033[0m"
        select f in "${ssh_files[@]}"; do [ -n "$f" ] && SSH_TAR="$f" && break; done
        tput civis
    fi
    OPENSSH_VERSION="${SSH_TAR#openssh-}"; OPENSSH_VERSION="${OPENSSH_VERSION%.tar.gz}"

    ssl_files=(openssl-*.tar.gz)
    [ ! -e "${ssl_files[0]}" ] && error_exit "未找到 openssl-*.tar.gz"
    if [ ${#ssl_files[@]} -eq 1 ]; then
        SSL_TAR="${ssl_files[0]}"
    else
        tput cnorm
        echo -e "\033[1;33m[?] 请选择 OpenSSL 版本:\033[0m"
        select f in "${ssl_files[@]}"; do [ -n "$f" ] && SSL_TAR="$f" && break; done
        tput civis
    fi
    OPENSSL_VERSION="${SSL_TAR#openssl-}"; OPENSSL_VERSION="${OPENSSL_VERSION%.tar.gz}"

    askpass_files=(x11-ssh-askpass-*.tar.gz)
    if [ -e "${askpass_files[0]}" ]; then
        ASKPASS_TAR="${askpass_files[0]}"
        ASKPASS_VERSION="${ASKPASS_TAR#x11-ssh-askpass-}"; ASKPASS_VERSION="${ASKPASS_VERSION%.tar.gz}"
        HAS_ASKPASS=true
    else
        ASKPASS_TAR=""
        HAS_ASKPASS=false
    fi
}

# === UI 执行函数 ===
function run_task {
    local desc="$1"
    local log_file="${LOG_DIR}/$2"
    shift 2
    local cmd="$@"

    echo -ne "   Target: \033[1;34m${desc}\033[0m ... "

    local start_time=$(date +%s)
    eval "$cmd" > "$log_file" 2>&1 &
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'

    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [\033[1;32m%c\033[0m] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done

    wait $pid
    local exit_code=$?
    local duration=$(( $(date +%s) - start_time ))

    if [ $exit_code -eq 0 ]; then
        echo -e "\033[1;32m[OK]\033[0m \033[90m(${duration}s)\033[0m"
    else
        echo -e "\033[1;31m[FAILED]\033[0m \033[90m(${duration}s)\033[0m"
        echo "-------------------------------------------------------"
        tail -n 20 "$log_file"
        echo "-------------------------------------------------------"
        error_exit "构建步骤失败"
    fi
}

# === 生成构建文件 ===
function generate_build_files {
    cat > ${RPMBUILD_DIR}/SOURCES/sshd.pam <<EOF
#%PAM-1.0
auth       required     pam_sepermit.so
auth       include      password-auth
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    required     pam_selinux.so open env_params
session    optional     pam_keyinit.so force revoke
session    include      password-auth
EOF

    cat > ${RPMBUILD_DIR}/SOURCES/sshd.service <<EOF
[Unit]
Description=OpenSSH server daemon
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target

[Service]
Type=simple
ExecStartPre=/usr/bin/ssh-keygen -A
ExecStart=/usr/sbin/sshd -D
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    if [ "$HAS_ASKPASS" = true ]; then
        SOURCE1_LINE="Source1: ${ASKPASS_TAR}"
    else
        SOURCE1_LINE="# Source1: Askpass not present"
    fi

    cat > ${RPMBUILD_DIR}/SPECS/openssh.spec <<SPEC_EOF
%define ver ${OPENSSH_VERSION}
%define rel ${RPM_RELEASE}%{?dist}
%define openssl_ver ${OPENSSL_VERSION}

Summary: OpenSSH with Static OpenSSL %{openssl_ver}
Name: openssh
Version: %{ver}
Release: %{rel}
Source0: ${SSH_TAR}
${SOURCE1_LINE}
Source2: sshd.pam
Source3: ${SSL_TAR}
Source4: sshd.service
License: BSD
Group: Applications/Internet
BuildRoot: %{_tmppath}/%{name}-%{version}-buildroot
BuildRequires: gcc, make, perl, zlib-devel, pam-devel
BuildRequires: perl-IPC-Cmd
Requires: systemd

%define debug_package %{nil}

%description
OpenSSH %{version} with statically linked OpenSSL %{openssl_ver}.

%package server
Summary: The OpenSSH server daemon
Requires: openssh = %{version}-%{release}
Requires: systemd

%description server
OpenSSH Server with static OpenSSL.

%package clients
Summary: OpenSSH clients
Requires: openssh = %{version}-%{release}

%description clients
OpenSSH Clients with static OpenSSL.

%prep
%setup -q
mkdir -p openssl_static
tar xfz %{SOURCE3} --strip-components=1 -C openssl_static
pushd openssl_static
./config --prefix=/opt/openssl-static --libdir=lib -fPIC no-shared
make -j\$(nproc)
make install_sw DESTDIR=\$(pwd)/../openssl_install
popd

%build
%define openssl_install_path %{_builddir}/%{name}-%{version}/openssl_install/opt/openssl-static
export LIBS='-lpthread -ldl -lz'
./configure --prefix=/usr --sysconfdir=/etc/ssh --libexecdir=/usr/libexec/openssh --with-ssl-dir=%{openssl_install_path} --without-openssl-header-check --with-zlib --with-pam --with-md5-passwords --without-zlib-version-check
perl -pi -e 's|-lcrypto|%{openssl_install_path}/lib/libcrypto.a -lpthread -ldl -lz|g' Makefile
perl -pi -e 's|-lssl|%{openssl_install_path}/lib/libssl.a|g' Makefile
make -j\$(nproc)

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}
install -m 755 contrib/ssh-copy-id %{buildroot}/usr/bin/
install -m 644 contrib/ssh-copy-id.1 %{buildroot}/usr/share/man/man1/
install -D -m 644 %{SOURCE2} %{buildroot}/etc/pam.d/sshd
mkdir -p %{buildroot}/usr/lib/systemd/system/
install -m 644 %{SOURCE4} %{buildroot}/usr/lib/systemd/system/sshd.service
rm -f %{buildroot}/usr/share/info/dir
cat << CONFIG >> %{buildroot}/etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
CONFIG

%clean
rm -rf %{buildroot}

%post server
systemctl daemon-reload
if ls /etc/ssh/ssh_host_*_key >/dev/null 2>&1; then chmod 600 /etc/ssh/ssh_host_*_key; fi
systemctl enable sshd
systemctl restart sshd

%preun server
if [ \$1 -eq 0 ]; then systemctl disable --now sshd; fi

%files
%defattr(-,root,root)
/etc/ssh/moduli
/etc/ssh/ssh_config
/etc/ssh/sshd_config
/usr/libexec/openssh/ssh-keysign
/usr/libexec/openssh/ssh-pkcs11-helper
/usr/libexec/openssh/ssh-sk-helper
/usr/share/man/man*/*

%files server
%defattr(-,root,root)
/usr/lib/systemd/system/sshd.service
/etc/pam.d/sshd
/usr/sbin/sshd
/usr/libexec/openssh/sftp-server
/usr/libexec/openssh/sshd-session
/usr/libexec/openssh/sshd-auth

%files clients
%defattr(-,root,root)
/usr/bin/ssh
/usr/bin/scp
/usr/bin/sftp
/usr/bin/ssh-add
/usr/bin/ssh-agent
/usr/bin/ssh-keygen
/usr/bin/ssh-keyscan
/usr/bin/ssh-copy-id
SPEC_EOF
}

# ================= 主流程 =================
OS_TAG=$(get_os_tag)
ARCH_TAG=$(get_arch)

detect_source_files

clear
echo -e "\033[1;37m========================================================================\033[0m"
echo -e "\033[1;37m                OpenSSH RPM Builder \033[1;33m${SCRIPT_VERSION}\033[1;37m by \033[1;33m${SCRIPT_AUTHOR}\033[0m"
echo -e "\033[1;37m========================================================================\033[0m"

echo -e " 📦 OpenSSH 源码 : \033[1;32m${SSH_TAR}\033[0m (v${OPENSSH_VERSION})"
echo -e " 🔒 OpenSSL 源码 : \033[1;32m${SSL_TAR}\033[0m (v${OPENSSL_VERSION})"
if [ "$HAS_ASKPASS" = true ]; then
    echo -e " 🔑 Askpass 源码 : \033[1;32m${ASKPASS_TAR}\033[0m (v${ASKPASS_VERSION})"
else
    echo -e " 🔑 Askpass 源码 : \033[1;30m未检测到 (自动跳过)\033[0m"
fi
echo -e " 📂 输出路径     : \033[1;32m${OUTPUT_DIR}\033[0m"
echo -e " 📝 日志路径     : \033[1;32m${LOG_DIR}\033[0m"
echo -e "\033[1;37m========================================================================\033[0m"
echo

# 1. 依赖选择
echo -ne "   Target: \033[1;34m依赖检查\033[0m ... "
tput cnorm
echo
echo -e "   \033[90m--------------------------------------------\033[0m"
echo -e "   1) \033[1;32m安装\033[0m"
echo -e "   2) \033[1;33m跳过\033[0m"
echo -e "   \033[90m--------------------------------------------\033[0m"
read -p "   请输入选项 [1-2]: " install_choice
tput civis

if [ "$install_choice" == "1" ]; then
    run_task "安装依赖组件" "02_yum_install.log" \
        "yum install -y rpm-build gcc gcc-c++ make perl perl-IPC-Cmd perl-Data-Dumper perl-Pod-Html zlib-devel pam-devel krb5-devel libXt-devel imake gtk2-devel perl-devel perl-Time-Piece systemd-devel"
else
    echo -e "   -> \033[1;33m跳过依赖安装\033[0m"
fi

# 2. 初始化
run_task "初始化 rpmbuild 目录" "03_init_dir.log" \
    "rm -rf ${RPMBUILD_DIR} && mkdir -p ${RPMBUILD_DIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}"

# 3. 复制
run_task "准备源码文件" "04_copy_src.log" \
    "cp ${BASE_DIR}/${SSH_TAR} ${RPMBUILD_DIR}/SOURCES/ && \
     cp ${BASE_DIR}/${SSL_TAR} ${RPMBUILD_DIR}/SOURCES/ && \
     ([ '$HAS_ASKPASS' = true ] && cp ${BASE_DIR}/${ASKPASS_TAR} ${RPMBUILD_DIR}/SOURCES/ || true)"

# 4. 配置
run_task "生成 SPEC 配置文件" "05_gen_spec.log" \
    "generate_build_files"

# 5. 编译
trap cleanup_turbo INT TERM
run_task "\033[1;33m[极速模式]\033[0m \033[1;34m编译并打包 RPM\033[0m (按下 \033[1;31mCtrl+C\033[0m 进一步加速)" "06_rpmbuild.log" \
    "rpmbuild -bb ${RPMBUILD_DIR}/SPECS/openssh.spec"

# 6. 打包
trap cleanup_standard INT TERM
PACKAGE_NAME="openssh-${OPENSSH_VERSION}-rpms-${OS_TAG}-${ARCH_TAG}"
TAR_NAME="${PACKAGE_NAME}.tar.gz"

run_task "整理并压缩安装包" "07_package.log" \
    "mkdir -p ${OUTPUT_DIR}/${PACKAGE_NAME} && \
     cp ${RPMBUILD_DIR}/RPMS/x86_64/*.rpm ${OUTPUT_DIR}/${PACKAGE_NAME}/ && \
     cd ${OUTPUT_DIR} && \
     tar czf ${TAR_NAME} ${PACKAGE_NAME} && \
     rm -rf ${PACKAGE_NAME}"

# 结束
trap - EXIT INT TERM
rm -rf "$LOG_DIR" "$RPMBUILD_DIR"
tput cnorm

echo
echo -e "\033[1;37m========================================================================\033[0m"
echo -e " 🎉 \033[1;32m构建成功！\033[0m"
echo -e " 🧹 \033[1;32m临时日志与构建目录已自动清理\033[0m"
echo -e " 📦 文件位置: \033[1;37m${OUTPUT_DIR}/${TAR_NAME}\033[0m"
echo -e "\033[1;37m========================================================================\033[0m"
ls -lh ${OUTPUT_DIR}/${TAR_NAME}
echo

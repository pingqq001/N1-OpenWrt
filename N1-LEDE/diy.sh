#!/bin/bash
# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

mkdir -p scripts
cat > scripts/download.pl << 'EOF'
#!/usr/bin/perl
my $url = shift;
# 替换内核下载地址
$url =~ s|https://git\.kernel\.org/pub/scm/linux/kernel/git/stable/linux\.git|https://mirror.tuna.tsinghua.edu.cn/git/linux-stable.git|;
exec("wget", "-O", @ARGV) if $url =~ /linux\.git/;
exec("wget", "--passive-ftp", "-O", @ARGV);
EOF
chmod +x scripts/download.pl

# ======== 修改内核下载地址 ========
echo "修改内核下载地址为清华镜像..."
sed -i 's|https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git|https://mirror.tuna.tsinghua.edu.cn/git/linux-stable.git|g' include/kernel-defaults.mk
sed -i 's|KERNEL_PATCHVER:=.*|KERNEL_PATCHVER:=5.15|g' target/linux/armvirt/Makefile
# Add packages
#添加科学上网源
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone -b 18.06 --single-branch --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone -b 18.06 --single-branch --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic
git clone --depth=1 https://github.com/sirpdboy/luci-app-ddns-go package/ddnsgo
#git clone --depth=1 https://github.com/sirpdboy/NetSpeedTest package/NetSpeedTest

git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone -b lua --single-branch --depth 1 https://github.com/sbwml/luci-app-alist package/alist
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky
#添加自定义的软件包源
#git_sparse_clone main https://github.com/kiddin9/kwrt-packages ddns-go
#git_sparse_clone main https://github.com/kiddin9/kwrt-packages luci-app-ddns-go
# Remove packages
#删除lean库中的插件，使用自定义源中的包。
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/applications/luci-app-mosdns
#rm -rf feeds/luci/themes/luci-theme-design
#rm -rf feeds/luci/applications/luci-app-design-config

# Default IP
sed -i 's/192.168.1.1/192.168.2.2/g' package/base-files/files/bin/config_generate

#修改默认时间格式
sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $(find ./package/*/autocore/files/ -type f -name "index.htm")
# ======== 将内核修改命令移到脚本末尾 ========
echo "修改内核下载地址为清华镜像..."
# 等待源码初始化完成
sleep 5
# 检查文件是否存在，如果存在则修改
if [ -f include/kernel-defaults.mk ]; then
    sed -i 's|https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git|https://mirror.tuna.tsinghua.edu.cn/git/linux-stable.git|g' include/kernel-defaults.mk
    echo "已修改 include/kernel-defaults.mk"
else
    echo "警告: include/kernel-defaults.mk 文件不存在"
fi

if [ -f target/linux/armvirt/Makefile ]; then
    sed -i 's|KERNEL_PATCHVER:=.*|KERNEL_PATCHVER:=5.15|g' target/linux/armvirt/Makefile
    echo "已修改 target/linux/armvirt/Makefile"
else
    echo "警告: target/linux/armvirt/Makefile 文件不存在"
fi

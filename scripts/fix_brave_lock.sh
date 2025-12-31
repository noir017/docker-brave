#!/bin/bash

# 解决Brave浏览器配置文件锁定问题
# 用法: ./fix_brave_lock.sh [BRAVE_DIR]
# 如果传入参数，使用参数作为BraVE_DIR
# 如果没有传入参数，使用环境变量BRAVE_DIR

set -euo pipefail

# 函数：显示使用说明
show_usage() {
    echo "Usage: $0 [BRAVE_DIR]"
    echo "如果传入参数，使用参数作为BRAVE_DIR"
    echo "如果没有传入参数，使用环境变量BRAVE_DIR"
    echo ""
    echo "示例:"
    echo "  $0 ~/.config/BraveSoftware/Brave-Browser"
    echo "  export BRAVE_DIR=~/.config/BraveSoftware/Brave-Browser && $0"
    echo ""
    echo "常见的Brave配置文件路径:"
    echo "  Linux: ~/.config/BraveSoftware/Brave-Browser"
    echo "  macOS: ~/Library/Application Support/BraveSoftware/Brave-Browser"
    echo "  Windows: %LOCALAPPDATA%\BraveSoftware\Brave-Browser"
}

# 函数：清理Brave配置文件
clean_brave_profile() {
    local profile_dir="$1"
    
    if [[ ! -d "$profile_dir" ]]; then
        echo "错误: 目录不存在: $profile_dir"
        return 1
    fi
    
    echo "正在清理Brave配置文件: $profile_dir"
    
    # 查找并删除锁定文件
    local lock_files=(
        "$profile_dir/SingletonLock"
        "$profile_dir/SingletonSocket"
        "$profile_dir/Lockfile"
        "$profile_dir/.lock"
    )
    
    local found_lock=false
    
    for lock_file in "${lock_files[@]}"; do
        if [[ -e "$lock_file" ]]; then
            echo "删除锁定文件: $lock_file"
            rm -f "$lock_file"
            found_lock=true
        fi
    done
    
    # 如果找不到常见的锁定文件，尝试使用find查找可能的锁定文件
    if [[ "$found_lock" == false ]]; then
        echo "正在搜索其他可能的锁定文件..."
        local additional_locks=$(find "$profile_dir" -type f -name "*lock*" -o -name "*Lock*" -o -name "*LOCK*" 2>/dev/null || true)
        
        if [[ -n "$additional_locks" ]]; then
            echo "找到其他锁定文件:"
            echo "$additional_locks"
            echo "$additional_locks" | while read -r lock; do
                echo "删除: $lock"
                rm -f "$lock"
            done
            found_lock=true
        fi
    fi
    
    # 清理Chrome的锁定文件（Brave基于Chromium）
    local chrome_lock_file="$profile_dir/chrome_delegate_lock_"
    if [[ -e "$chrome_lock_file" ]]; then
        echo "删除Chrome锁定文件: $chrome_lock_file"
        rm -f "$chrome_lock_file"
        found_lock=true
    fi
    
    # 清理可能的进程锁文件
    local pid_files=$(find "$profile_dir" -type f -name "*.pid" 2>/dev/null || true)
    if [[ -n "$pid_files" ]]; then
        echo "删除PID文件:"
        echo "$pid_files"
        echo "$pid_files" | while read -r pid_file; do
            echo "删除: $pid_file"
            rm -f "$pid_file"
        done
        found_lock=true
    fi
    
    if [[ "$found_lock" == true ]]; then
        echo "✅ 锁定文件已清理完成"
    else
        echo "ℹ️  未找到锁定文件，但配置文件目录存在"
        echo "尝试清理可能存在的临时文件..."
        
        # 清理临时文件
        find "$profile_dir" -type f -name "*.tmp" -o -name "*.temp" -o -name "tmp*" 2>/dev/null | while read -r tmp_file; do
            echo "删除临时文件: $tmp_file"
            rm -f "$tmp_file"
        done
    fi
    
    # 检查是否有Brave进程仍在运行
    echo "检查是否有Brave进程仍在运行..."
    if pgrep -f "brave" > /dev/null 2>&1; then
        echo "⚠️  检测到Brave进程仍在运行，建议先关闭所有Brave进程"
        echo "   运行以下命令关闭Brave:"
        echo "   pkill -f brave"
    else
        echo "✅ 没有检测到运行中的Brave进程"
    fi
    
    return 0
}

# 主程序
main() {
    local brave_dir=""
    
    # 检查是否传入参数
    if [[ $# -gt 0 ]]; then
        brave_dir="$1"
        echo "使用参数指定的目录: $brave_dir"
    elif [[ -n "${BRAVE_DIR:-}" ]]; then
        brave_dir="$BRAVE_DIR"
        echo "使用环境变量BRAVE_DIR: $brave_dir"
    else
        echo "错误: 未指定Brave配置文件目录"
        echo ""
        show_usage
        
        # 尝试使用默认路径
        local default_dir="$HOME/.config/BraveSoftware/Brave-Browser"
        echo ""
        echo "尝试使用默认路径: $default_dir"
        
        if [[ -d "$default_dir" ]]; then
            read -p "是否使用此默认路径? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                brave_dir="$default_dir"
            else
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    # 展开路径中的波浪号
    if [[ "$brave_dir" == ~* ]]; then
        brave_dir="${brave_dir/#\~/$HOME}"
    fi
    
    # 检查目录是否存在
    if [[ ! -d "$brave_dir" ]]; then
        echo "错误: 目录不存在: $brave_dir"
        echo "请检查路径是否正确"
        exit 1
    fi
    
    # 确认操作
    echo ""
    echo "⚠️  警告: 将清理Brave配置文件目录: $brave_dir"
    echo "这可能会重置某些浏览器设置"
    read -p "是否继续? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
    
    # 执行清理
    clean_brave_profile "$brave_dir"
    
    echo ""
    echo "🎉 清理完成!"
    echo "现在可以尝试重新启动Brave浏览器"
    
    # 提供重启建议
    echo ""
    echo "重启建议:"
    echo "1. 完全退出Brave浏览器"
    echo "2. 运行此脚本清理锁定文件"
    echo "3. 重新启动Brave"
    
    # 如果是容器环境，提供额外建议
    if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo ""
        echo "🔧 容器环境建议:"
        echo "在容器环境中，建议在启动脚本中添加以下步骤:"
        echo "1. 在启动Brave前运行此脚本清理锁定文件"
        echo "2. 确保容器重启时正确关闭Brave"
    fi
}

# 运行主程序
main "$@"
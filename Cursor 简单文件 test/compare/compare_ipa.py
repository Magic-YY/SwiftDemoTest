#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
IPA文件大小对比工具
比较新旧版本IPA文件的大小差异和资源变化
"""

import os
import zipfile
import json
from pathlib import Path
from collections import defaultdict

def get_file_size(filepath):
    """获取文件大小（字节）"""
    return os.path.getsize(filepath)

def format_size(size_bytes):
    """格式化文件大小显示（使用1000进制，与Mac Finder一致）"""
    if abs(size_bytes) >= 500 * 1000:  # 大于500KB使用MB
        return f"{size_bytes / (1000 * 1000):.2f} MB"
    else:
        return f"{size_bytes / 1000:.2f} KB"

def shorten_framework_name(framework_name):
    """缩短过长的Framework名称"""
    # 移除.framework后缀来处理
    name = framework_name.replace('.framework', '')
    
    # 定义常见的缩写规则
    abbreviations = {
        'SDWebImageWebPCoder': 'SDWebImageWebP',
        'flutter_image_compress_common': 'flutter_img_compress',
        'shared_preferences_foundation': 'shared_prefs_foundation',
        'permission_handler_apple': 'permission_handler',
        'path_provider_foundation': 'path_provider',
        'package_info_plus': 'package_info',
        'device_info_plus': 'device_info',
        'sqflite_darwin': 'sqflite',
    }
    
    # 应用缩写规则
    for long_name, short_name in abbreviations.items():
        if long_name in name:
            name = name.replace(long_name, short_name)
    
    # 如果名称仍然很长，截断并添加省略号
    if len(name) > 25:
        name = name[:22] + '...'
    
    return name + '.framework'

def analyze_ipa_content(ipa_path, aggregate_mode=True):
    """分析IPA文件内容
    
    Args:
        ipa_path: IPA文件路径
        aggregate_mode: 是否使用汇总模式。True时将子组件汇总到主framework
    """
    file_info = {}
    total_uncompressed_size = 0
    total_compressed_size = 0
    
    try:
        with zipfile.ZipFile(ipa_path, 'r') as zip_file:
            for file_info_obj in zip_file.filelist:
                if not file_info_obj.is_dir():
                    file_path = file_info_obj.filename
                    file_size = file_info_obj.file_size
                    compressed_size = file_info_obj.compress_size
                    
                    # 分类文件类型
                    file_type = categorize_file(file_path, aggregate_mode)
                    
                    file_info[file_path] = {
                        'size': file_size,
                        'type': file_type,
                        'compressed_size': compressed_size
                    }
                    total_uncompressed_size += file_size
                    total_compressed_size += compressed_size
    except Exception as e:
        print(f"解析IPA文件时出错: {e}")
        return {}, 0, 0
    
    return file_info, total_uncompressed_size, total_compressed_size

def categorize_file(file_path, aggregate_mode=True):
    """根据文件路径和扩展名分类文件
    
    Args:
        file_path: 文件路径
        aggregate_mode: 是否使用汇总模式。True时将子组件汇总到主framework，False时显示详细分类
    """
    path_lower = file_path.lower()
    
    # Framework文件 - 提取具体的framework名称和子组件
    if '.framework/' in path_lower:
        # 提取framework名称，例如从 "Frameworks/App.framework/App" 提取 "App.framework"
        framework_match = file_path.split('.framework/')[0]
        framework_name = framework_match.split('/')[-1] + '.framework'
        short_framework_name = shorten_framework_name(framework_name)
        
        if aggregate_mode:
            # 汇总模式：所有framework内的文件都归类到主framework
            return f'Framework - {short_framework_name}'
        else:
            # 详细模式：显示子组件分类
            remaining_path = file_path.split('.framework/', 1)[1]
            
            # 检查是否包含bundle
            if '.bundle/' in remaining_path:
                bundle_match = remaining_path.split('.bundle/')[0]
                bundle_name = bundle_match.split('/')[-1] + '.bundle'
                return f'Framework - {short_framework_name} → {bundle_name}'
            
            # 检查是否包含其他特殊目录结构
            if 'flutter_assets/' in remaining_path:
                # 进一步分析flutter_assets的子目录
                assets_path = remaining_path.split('flutter_assets/', 1)[1]
                if assets_path.startswith('packages/'):
                    package_path = assets_path.split('packages/', 1)[1]
                    package_name = package_path.split('/')[0]
                    return f'Framework - {short_framework_name} → flutter_assets → {package_name}'
                elif assets_path.startswith('shaders/'):
                    return f'Framework - {short_framework_name} → flutter_assets → shaders'
                elif assets_path.startswith('fonts/'):
                    return f'Framework - {short_framework_name} → flutter_assets → fonts'
                elif assets_path.startswith('assets/'):
                    return f'Framework - {short_framework_name} → flutter_assets → assets'
                else:
                    return f'Framework - {short_framework_name} → flutter_assets'
            
            # 普通framework文件
            return f'Framework - {short_framework_name}'
    elif file_path.endswith('.framework'):
        framework_name = Path(file_path).name
        short_name = shorten_framework_name(framework_name)
        return f'Framework - {short_name}'
    
    # 图片文件
    if any(ext in path_lower for ext in ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.ico']):
        return '图片资源'
    
    # 视频文件
    if any(ext in path_lower for ext in ['.mp4', '.mov', '.avi', '.m4v', '.3gp']):
        return '视频资源'
    
    # 音频文件
    if any(ext in path_lower for ext in ['.mp3', '.wav', '.aac', '.m4a', '.caf']):
        return '音频资源'
    
    # 字体文件
    if any(ext in path_lower for ext in ['.ttf', '.otf', '.woff']):
        return '字体资源'
    
    # NIB/Storyboard文件
    if any(ext in path_lower for ext in ['.nib', '.storyboard', '.xib']):
        return 'Interface文件'
    
    # 可执行文件
    if '/payload/' in path_lower and not '.' in Path(file_path).name:
        return '可执行文件'
    
    # 配置文件
    if any(ext in path_lower for ext in ['.plist', '.json', '.xml', '.strings']):
        return '配置文件'
    
    # 数据库文件
    if any(ext in path_lower for ext in ['.db', '.sqlite', '.realm']):
        return '数据库文件'
    
    # 其他文件
    return '其他文件'

def compare_ipa_files(old_ipa_path, new_ipa_path):
    """比较两个IPA文件"""
    print("正在分析旧版本IPA文件...")
    # 汇总模式分析：用于生成类型总览
    old_files_agg, old_total_size, old_compressed_total = analyze_ipa_content(old_ipa_path, aggregate_mode=True)
    # 详细模式分析：用于展示具体文件列表
    old_files_detail, _, _ = analyze_ipa_content(old_ipa_path, aggregate_mode=False)
    old_file_size = get_file_size(old_ipa_path)  # IPA文件本身大小
    
    print("正在分析新版本IPA文件...")
    # 汇总模式分析：用于生成类型总览
    new_files_agg, new_total_size, new_compressed_total = analyze_ipa_content(new_ipa_path, aggregate_mode=True)
    # 详细模式分析：用于展示具体文件列表
    new_files_detail, _, _ = analyze_ipa_content(new_ipa_path, aggregate_mode=False)
    new_file_size = get_file_size(new_ipa_path)  # IPA文件本身大小
    
    # 计算总体积变化（解压后内容）
    size_diff = new_total_size - old_total_size
    # 计算IPA文件本身大小变化
    file_size_diff = new_file_size - old_file_size
    
    # 按类型分组统计（使用压缩后大小，更准确反映IPA包的实际贡献）- 使用汇总数据
    old_by_type_compressed = defaultdict(int)
    new_by_type_compressed = defaultdict(int)
    old_by_type_uncompressed = defaultdict(int)
    new_by_type_uncompressed = defaultdict(int)
    
    for file_path, info in old_files_agg.items():
        old_by_type_compressed[info['type']] += info['compressed_size']
        old_by_type_uncompressed[info['type']] += info['size']
    
    for file_path, info in new_files_agg.items():
        new_by_type_compressed[info['type']] += info['compressed_size']
        new_by_type_uncompressed[info['type']] += info['size']
    
    # 生成报告 - 使用详细数据来展示文件列表
    report = generate_report(old_ipa_path, new_ipa_path, old_file_size, new_file_size, file_size_diff,
                           old_total_size, new_total_size, size_diff, old_files_detail, new_files_detail, 
                           old_by_type_compressed, new_by_type_compressed, old_by_type_uncompressed, new_by_type_uncompressed)
    
    return report

def generate_report(old_ipa_path, new_ipa_path, old_file_size, new_file_size, file_size_diff,
                   old_total_size, new_total_size, size_diff, old_files, new_files, 
                   old_by_type_compressed, new_by_type_compressed, old_by_type_uncompressed, new_by_type_uncompressed):
    """生成对比报告"""
    report_lines = []
    
    # 标题
    report_lines.append("# IPA文件大小对比报告\n")
    
    # 基本信息
    report_lines.append("## 基本信息")
    # 使用文件夹名称作为版本名称
    old_folder_name = Path(old_ipa_path).parent.name
    new_folder_name = Path(new_ipa_path).parent.name
    report_lines.append(f"- **{old_folder_name}版本IPA体积**: {format_size(old_file_size)}")
    report_lines.append(f"- **{new_folder_name}版本IPA体积**: {format_size(new_file_size)}")
    
    report_lines.append("")
    
    # IPA包体积增减总信息
    report_lines.append("## IPA包体积增减总信息")
    report_lines.append("")
    
    all_types = set(old_by_type_compressed.keys()) | set(new_by_type_compressed.keys())
    
    # 计算所有变化
    type_changes = []
    for file_type in all_types:
        old_size = old_by_type_compressed.get(file_type, 0)
        new_size = new_by_type_compressed.get(file_type, 0)
        type_diff = new_size - old_size
        if type_diff != 0:
            type_changes.append((file_type, type_diff, old_size, new_size))
    
    # 验证总和
    total_compressed_diff = sum([x[1] for x in type_changes])
    report_lines.append(f"**各类型变化总和**: {format_size(total_compressed_diff) if total_compressed_diff > 0 else format_size(abs(total_compressed_diff))}")
    report_lines.append(f"**IPA文件实际变化**: {format_size(file_size_diff)}")
    
    # 计算差异（zip头、元数据等）
    metadata_diff = file_size_diff - total_compressed_diff
    if abs(metadata_diff) > 1000:  # 超过1KB才显示
        report_lines.append(f"**差异（ZIP头/元数据等）**: {format_size(metadata_diff) if metadata_diff > 0 else format_size(abs(metadata_diff))}")
    
    report_lines.append("")
    
    # 生成HTML文件并添加链接
    html_file_path = generate_html_report(old_ipa_path, new_ipa_path, old_file_size, new_file_size, file_size_diff,
                                         old_total_size, new_total_size, size_diff, old_files, new_files, 
                                         old_by_type_compressed, new_by_type_compressed, old_by_type_uncompressed, new_by_type_uncompressed)
    
    # 使用urllib来正确编码URL
    import urllib.parse
    import urllib.request
    html_file_url = urllib.parse.urljoin('file:', urllib.request.pathname2url(html_file_path))
    report_lines.append(f"**📊 Web版报告**: [点击在浏览器中查看详细报告]({html_file_url})")
    report_lines.append(f"**📄 HTML文件路径**: {html_file_path}")
    report_lines.append("")
    report_lines.append("---")  # 分割线
    report_lines.append("")
    
    # 分离增大和减少的资源
    increased_types = [(file_type, type_diff, old_size, new_size) for file_type, type_diff, old_size, new_size in type_changes if type_diff > 0]
    decreased_types = [(file_type, type_diff, old_size, new_size) for file_type, type_diff, old_size, new_size in type_changes if type_diff < 0]
    
    # 按大小排序（由大到小）
    increased_types.sort(key=lambda x: x[1], reverse=True)
    decreased_types.sort(key=lambda x: abs(x[1]), reverse=True)
    
    # 获取所有文件和类型
    all_files = set(old_files.keys()) | set(new_files.keys())
    files_by_type = defaultdict(list)
    
    for file_path in all_files:
        old_info = old_files.get(file_path, {})
        new_info = new_files.get(file_path, {})
        file_type = new_info.get('type') or old_info.get('type', '其他文件')
        
        old_size = old_info.get('size', 0)
        new_size = new_info.get('size', 0)
        change = new_size - old_size
        
        # 确定状态
        if old_size == 0:
            status = "新增"
            status_priority = 1  # 新增排在最前
        elif new_size == 0:
            status = "删除"
            status_priority = 3  # 删除排在最后
        else:
            status = "修改"
            status_priority = 2  # 修改排在中间
        
        files_by_type[file_type].append({
            'path': file_path,
            'old_size': old_size,
            'new_size': new_size,
            'change': change,
            'status': status,
            'status_priority': status_priority
        })
    
    # 显示新增资源及其详细文件
    if increased_types:
        report_lines.append("## 📈 新增/增大的资源类型")
        report_lines.append("")
        report_lines.append("*按增大幅度由大到小排序：*")
        report_lines.append("")
        
        for file_type, type_diff, old_size, new_size in increased_types:
            # 计算真实大小变化（解压后）
            real_old_size = old_by_type_uncompressed.get(file_type, 0)
            real_new_size = new_by_type_uncompressed.get(file_type, 0)
            real_diff = real_new_size - real_old_size
            
            report_lines.append(f"- **{file_type}**: IPA增大 {format_size(type_diff)}，真实增大 {format_size(real_diff)}")
        
        report_lines.append("")
        
        # 为每个增大的资源类型生成详细表格
        for file_type, type_diff, old_size, new_size in increased_types:
            if file_type in files_by_type:
                files = files_by_type[file_type]
                
                # 过滤掉变化很小的文件（小于1KB的变化）
                significant_files = [f for f in files if abs(f['change']) >= 1024 or f['status'] in ['新增', '删除']]
                
                if significant_files:
                    # 按状态排序：新增(1) -> 修改(2) -> 删除(3)，然后按变化大小排序
                    significant_files.sort(key=lambda x: (x['status_priority'], -abs(x['change'])))
                    
                    # 限制每个类型最多显示20个文件
                    if len(significant_files) > 20:
                        significant_files = significant_files[:20]
                    
                    # 计算真实大小变化
                    real_old_size = old_by_type_uncompressed.get(file_type, 0)
                    real_new_size = new_by_type_uncompressed.get(file_type, 0)
                    real_diff = real_new_size - real_old_size
                    
                    report_lines.append(f"### 📄 {file_type} - 详细文件列表 (IPA增大: {format_size(type_diff)}，真实增大: {format_size(real_diff)})")
                    report_lines.append("")
                    report_lines.append("| 文件路径 | 旧版本大小 | 新版本大小 | 变化 | 状态 |")
                    report_lines.append("|---------|------------|------------|------|------|")
                    
                    for file_info in significant_files:
                        file_path = file_info['path']
                        old_size = file_info['old_size']
                        new_size = file_info['new_size']
                        change = file_info['change']
                        status = file_info['status']
                        
                        # 格式化大小显示
                        old_size_str = format_size(old_size) if old_size > 0 else "-"
                        new_size_str = format_size(new_size) if new_size > 0 else "-"
                        
                        # 变化量
                        if change > 0:
                            change_str = f"+{format_size(change)}"
                        elif change < 0:
                            change_str = f"-{format_size(abs(change))}"
                        else:
                            change_str = "无变化"
                        
                        # 截断过长的文件路径，特别处理Framework路径
                        display_path = file_path
                        if 'Framework' in display_path and len(display_path) > 40:
                            # 对于Framework路径，只显示framework名称和文件名
                            if '.framework/' in display_path:
                                parts = display_path.split('.framework/')
                                if len(parts) == 2:
                                    framework_part = parts[0].split('/')[-1] + '.framework'
                                    file_part = parts[1]
                                    # 如果文件路径仍然太长，截断文件路径部分
                                    if len(file_part) > 25:
                                        file_part = "..." + file_part[-22:]
                                    display_path = f"{framework_part}/{file_part}"
                        elif len(display_path) > 50:
                            display_path = "..." + display_path[-47:]
                        
                        report_lines.append(f"| {display_path} | {old_size_str} | {new_size_str} | {change_str} | {status} |")
                    
                    if len(files) > len(significant_files):
                        report_lines.append(f"\n*注: {file_type}类型共有 {len(files)} 个文件，仅显示变化较大的 {len(significant_files)} 个*")
                    
                    report_lines.append("")
    
    report_lines.append("---")  # 分割线
    report_lines.append("")
    
    # 显示减少资源及其详细文件
    if decreased_types:
        report_lines.append("## 📉 减少的资源类型")
        report_lines.append("")
        report_lines.append("*按减少幅度由大到小排序：*")
        report_lines.append("")
        
        for file_type, type_diff, old_size, new_size in decreased_types:
            # 计算真实大小变化（解压后）
            real_old_size = old_by_type_uncompressed.get(file_type, 0)
            real_new_size = new_by_type_uncompressed.get(file_type, 0)
            real_diff = real_new_size - real_old_size
            
            report_lines.append(f"- **{file_type}**: IPA减少 {format_size(abs(type_diff))}，真实减少 {format_size(abs(real_diff))}")
        
        report_lines.append("")
        
        # 为每个减少的资源类型生成详细表格
        for file_type, type_diff, old_size, new_size in decreased_types:
            if file_type in files_by_type:
                files = files_by_type[file_type]
                
                # 过滤掉变化很小的文件（小于1KB的变化）
                significant_files = [f for f in files if abs(f['change']) >= 1024 or f['status'] in ['新增', '删除']]
                
                if significant_files:
                    # 按状态排序：新增(1) -> 修改(2) -> 删除(3)，然后按变化大小排序
                    significant_files.sort(key=lambda x: (x['status_priority'], -abs(x['change'])))
                    
                    # 限制每个类型最多显示20个文件
                    if len(significant_files) > 20:
                        significant_files = significant_files[:20]
                    
                    # 计算真实大小变化
                    real_old_size = old_by_type_uncompressed.get(file_type, 0)
                    real_new_size = new_by_type_uncompressed.get(file_type, 0)
                    real_diff = real_new_size - real_old_size
                    
                    report_lines.append(f"### 📄 {file_type} - 详细文件列表 (IPA减少: {format_size(abs(type_diff))}，真实减少: {format_size(abs(real_diff))})")
                    report_lines.append("")
                    report_lines.append("| 文件路径 | 旧版本大小 | 新版本大小 | 变化 | 状态 |")
                    report_lines.append("|---------|------------|------------|------|------|")
                    
                    for file_info in significant_files:
                        file_path = file_info['path']
                        old_size = file_info['old_size']
                        new_size = file_info['new_size']
                        change = file_info['change']
                        status = file_info['status']
                        
                        # 格式化大小显示
                        old_size_str = format_size(old_size) if old_size > 0 else "-"
                        new_size_str = format_size(new_size) if new_size > 0 else "-"
                        
                        # 变化量
                        if change > 0:
                            change_str = f"+{format_size(change)}"
                        elif change < 0:
                            change_str = f"-{format_size(abs(change))}"
                        else:
                            change_str = "无变化"
                        
                        # 截断过长的文件路径，特别处理Framework路径
                        display_path = file_path
                        if 'Framework' in display_path and len(display_path) > 40:
                            # 对于Framework路径，只显示framework名称和文件名
                            if '.framework/' in display_path:
                                parts = display_path.split('.framework/')
                                if len(parts) == 2:
                                    framework_part = parts[0].split('/')[-1] + '.framework'
                                    file_part = parts[1]
                                    # 如果文件路径仍然太长，截断文件路径部分
                                    if len(file_part) > 25:
                                        file_part = "..." + file_part[-22:]
                                    display_path = f"{framework_part}/{file_part}"
                        elif len(display_path) > 50:
                            display_path = "..." + display_path[-47:]
                        
                        report_lines.append(f"| {display_path} | {old_size_str} | {new_size_str} | {change_str} | {status} |")
                    
                    if len(files) > len(significant_files):
                        report_lines.append(f"\n*注: {file_type}类型共有 {len(files)} 个文件，仅显示变化较大的 {len(significant_files)} 个*")
                    
                    report_lines.append("")
    
    return "\n".join(report_lines)

def generate_html_report(old_ipa_path, new_ipa_path, old_file_size, new_file_size, file_size_diff,
                        old_total_size, new_total_size, size_diff, old_files, new_files, 
                        old_by_type_compressed, new_by_type_compressed, old_by_type_uncompressed, new_by_type_uncompressed):
    """生成HTML格式的报告"""
    import os
    from datetime import datetime
    
    current_dir = Path(__file__).parent
    html_file_path = current_dir / "ipa_comparison_report.html"
    
    # 计算变化数据
    all_types = set(old_by_type_compressed.keys()) | set(new_by_type_compressed.keys())
    type_changes = []
    for file_type in all_types:
        old_size = old_by_type_compressed.get(file_type, 0)
        new_size = new_by_type_compressed.get(file_type, 0)
        type_diff = new_size - old_size
        if type_diff != 0:
            type_changes.append((file_type, type_diff, old_size, new_size))
    
    total_compressed_diff = sum([x[1] for x in type_changes])
    metadata_diff = file_size_diff - total_compressed_diff
    
    # 分离增大和减少的资源
    increased_types = [(file_type, type_diff, old_size, new_size) for file_type, type_diff, old_size, new_size in type_changes if type_diff > 0]
    decreased_types = [(file_type, type_diff, old_size, new_size) for file_type, type_diff, old_size, new_size in type_changes if type_diff < 0]
    
    increased_types.sort(key=lambda x: x[1], reverse=True)
    decreased_types.sort(key=lambda x: abs(x[1]), reverse=True)
    
    # 获取详细文件信息
    def get_files_by_type():
        all_files = set(old_files.keys()) | set(new_files.keys())
        files_by_type = defaultdict(list)
        
        for file_path in all_files:
            old_info = old_files.get(file_path, {})
            new_info = new_files.get(file_path, {})
            file_type = new_info.get('type') or old_info.get('type', '其他文件')
            
            old_size = old_info.get('size', 0)
            new_size = new_info.get('size', 0)
            change = new_size - old_size
            
            # 确定状态
            if old_size == 0:
                status = "新增"
                status_priority = 1
            elif new_size == 0:
                status = "删除"
                status_priority = 3
            else:
                status = "修改"
                status_priority = 2
            
            files_by_type[file_type].append({
                'path': file_path,
                'old_size': old_size,
                'new_size': new_size,
                'change': change,
                'status': status,
                'status_priority': status_priority
            })
        
        # 为每个类型的文件排序
        for file_type in files_by_type:
            files_by_type[file_type].sort(key=lambda x: (x['status_priority'], -abs(x['change'])))
        
        return files_by_type
    
    files_by_type = get_files_by_type()
    
    html_content = f"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPA文件大小对比报告</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #2c3e50;
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }}
        h2 {{
            color: #34495e;
            border-left: 4px solid #3498db;
            padding-left: 15px;
            margin-top: 30px;
        }}
        .info-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 25px;
            margin-bottom: 35px;
        }}
        .info-card {{
            background: #ecf0f1;
            padding: 20px;
            border-radius: 6px;
            border-left: 4px solid #3498db;
        }}
        .version-label {{
            color: #2c3e50;
            font-weight: normal;
            margin-right: 10px;
        }}
        .version-size {{
            color: #2c3e50;
            font-weight: bold;
            font-size: 1.1em;
        }}
        .summary-box {{
            background: #f8f9fa;
            color: #2c3e50;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
            border: 1px solid #dee2e6;
        }}
        .summary-box h3 {{
            margin: 0 0 15px 0;
            font-size: 1.2em;
        }}
        .summary-stats {{
            display: flex;
            justify-content: center;
            align-items: center;
            flex-wrap: wrap;
            gap: 40px;
        }}
        .stat-item {{
            text-align: center;
            padding: 15px 25px;
            border-radius: 8px;
            min-width: 180px;
            position: relative;
        }}
        .stat-item.ipa-change {{
            background: #e3f2fd;
            border: 2px solid #2196f3;
        }}
        .stat-item.real-change {{
            background: #ffebee;
            border: 2px dashed #e74c3c;
        }}
        .stat-item.ipa-change::before {{
            content: "📦";
            position: absolute;
            top: -8px;
            left: -8px;
            background: #2196f3;
            color: white;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
        }}
        .stat-item.real-change::before {{
            content: "💾";
            position: absolute;
            top: -8px;
            left: -8px;
            background: #e74c3c;
            color: white;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
        }}
        .stat-number {{
            font-size: 1.6em;
            font-weight: bold;
            display: block;
            margin-bottom: 5px;
        }}
        .stat-label {{
            font-size: 0.9em;
            opacity: 0.9;
            font-weight: 500;
        }}
        .increase {{
            color: #ff6b6b;
        }}
        .decrease {{
            color: #51cf66;
        }}
        .resource-section {{
            margin: 30px 0;
        }}
        .resource-list {{
            background: #f8f9fa;
            border-radius: 6px;
            padding: 20px;
            margin: 15px 0;
        }}
        .resource-item {{
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 6px;
            margin-bottom: 10px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }}
        .resource-header {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px 20px;
            cursor: pointer;
            transition: background-color 0.2s;
        }}
        .resource-header:hover {{
            background-color: #f8f9fa;
        }}
        .resource-header.active {{
            background-color: #e9ecef;
        }}
        .resource-name {{
            font-weight: 500;
            color: #2c3e50;
            display: flex;
            align-items: center;
        }}
        .expand-icon {{
            margin-right: 10px;
            transition: transform 0.2s;
            font-size: 12px;
        }}
        .expand-icon.expanded {{
            transform: rotate(90deg);
        }}
        .resource-change {{
            font-weight: bold;
            padding: 6px 12px;
            border-radius: 4px;
            color: white;
        }}
        .change-increase {{
            background-color: #e74c3c;
        }}
        .change-decrease {{
            background-color: #27ae60;
        }}
        .ipa-badge {{
            background-color: #2196f3 !important;
        }}
        .real-badge {{
            background-color: #e74c3c !important;
        }}
        .resource-change-container {{
            display: flex;
            gap: 8px;
            align-items: center;
        }}
        .details-panel {{
            display: none;
            padding: 0 20px 20px 20px;
            background-color: #f8f9fa;
        }}
        .details-panel.show {{
            display: block;
        }}
        .file-table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            font-size: 0.9em;
        }}
        .file-table th {{
            background-color: #34495e;
            color: white;
            padding: 10px;
            text-align: left;
            font-weight: 500;
        }}
        .file-table td {{
            padding: 8px 10px;
            border-bottom: 1px solid #dee2e6;
            background-color: white;
        }}
        .file-table tr:hover td {{
            background-color: #f1f3f4;
        }}
        .status-badge {{
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: 500;
        }}
        .status-new {{
            background-color: #d4edda;
            color: #155724;
        }}
        .status-modified {{
            background-color: #fff3cd;
            color: #856404;
        }}
        .status-deleted {{
            background-color: #f8d7da;
            color: #721c24;
        }}
        .file-change {{
            font-weight: 500;
        }}
        .file-change.positive {{
            color: #e74c3c;
        }}
        .file-change.negative {{
            color: #27ae60;
        }}
        .timestamp {{
            text-align: center;
            color: #7f8c8d;
            margin-top: 30px;
            font-size: 0.9em;
        }}
        .divider {{
            border: none;
            height: 2px;
            background: linear-gradient(to right, transparent, #3498db, transparent);
            margin: 30px 0;
        }}
        .file-path {{
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Roboto Mono', monospace;
            font-size: 0.85em;
            color: #495057;
        }}
    </style>
    <script>
        function toggleDetails(element) {{
            const panel = element.nextElementSibling;
            const icon = element.querySelector('.expand-icon');
            const header = element;
            
            if (panel.classList.contains('show')) {{
                panel.classList.remove('show');
                icon.classList.remove('expanded');
                header.classList.remove('active');
            }} else {{
                panel.classList.add('show');
                icon.classList.add('expanded');
                header.classList.add('active');
            }}
        }}
    </script>
</head>
<body>
    <div class="container">
        <h1>📊 IPA文件大小对比报告</h1>
        
        <div class="info-grid">
            <div class="info-card">
                <span class="version-label">{Path(old_ipa_path).parent.name}版本IPA体积:</span> 
                <span class="version-size">{format_size(old_file_size)}</span>
            </div>
            <div class="info-card">
                <span class="version-label">{Path(new_ipa_path).parent.name}版本IPA体积:</span> 
                <span class="version-size">{format_size(new_file_size)}</span>
            </div>
        </div>

        <div class="summary-box">
            <h3>📈 总体变化</h3>
            <div class="summary-stats">
                <div class="stat-item ipa-change">
                    <span class="stat-number {'increase' if file_size_diff > 0 else 'decrease'}">
                        {'+' if file_size_diff > 0 else ''}{format_size(file_size_diff)}
                    </span>
                    <span class="stat-label">IPA体积变化</span>
                </div>
                <div class="stat-item real-change">
                    <span class="stat-number {'increase' if size_diff > 0 else 'decrease'}">
                        {'+' if size_diff > 0 else ''}{format_size(size_diff)}
                    </span>
                    <span class="stat-label">真实体积变化</span>
                </div>
            </div>
        </div>

        <hr class="divider">

        <div class="resource-section">
            <h2>📈 新增/增大的资源类型</h2>
            <p style="color: #6c757d; margin-bottom: 20px; font-style: italic;">以下显示各资源类型在IPA包中增加的体积大小（基于压缩后大小）</p>
            <div class="resource-list">"""
    
    # 生成可展开的增大资源类型
    for file_type, type_diff, old_size, new_size in increased_types:
        # 计算真实大小变化
        real_old_size = old_by_type_uncompressed.get(file_type, 0)
        real_new_size = new_by_type_uncompressed.get(file_type, 0)
        real_diff = real_new_size - real_old_size
        
        # 获取该类型的详细文件列表
        type_files = files_by_type.get(file_type, [])
        significant_files = [f for f in type_files if abs(f['change']) >= 1024 or f['status'] in ['新增', '删除']]
        
        if len(significant_files) > 20:
            significant_files = significant_files[:20]
        
        html_content += f"""
                <div class="resource-item">
                    <div class="resource-header" onclick="toggleDetails(this)">
                        <span class="resource-name">
                            <span class="expand-icon">▶</span>
                            {file_type}
                        </span>
                        <div class="resource-change-container">
                            <span class="resource-change change-increase ipa-badge">IPA +{format_size(type_diff)}</span>
                            <span class="resource-change change-increase real-badge">真实 +{format_size(real_diff)}</span>
                        </div>
                    </div>
                    <div class="details-panel">
                        <table class="file-table">
                            <thead>
                                <tr>
                                    <th>文件路径</th>
                                    <th>旧版本大小</th>
                                    <th>新版本大小</th>
                                    <th>变化</th>
                                    <th>状态</th>
                                </tr>
                            </thead>
                            <tbody>"""
        
        for file_info in significant_files:
            file_path = file_info['path']
            old_size = file_info['old_size']
            new_size = file_info['new_size']
            change = file_info['change']
            status = file_info['status']
            
            # 格式化显示路径
            display_path = file_path
            if 'Framework' in display_path and len(display_path) > 40:
                if '.framework/' in display_path:
                    parts = display_path.split('.framework/')
                    if len(parts) == 2:
                        framework_part = parts[0].split('/')[-1] + '.framework'
                        file_part = parts[1]
                        if len(file_part) > 25:
                            file_part = "..." + file_part[-22:]
                        display_path = f"{framework_part}/{file_part}"
            elif len(display_path) > 50:
                display_path = "..." + display_path[-47:]
            
            # 格式化大小
            old_size_str = format_size(old_size) if old_size > 0 else "-"
            new_size_str = format_size(new_size) if new_size > 0 else "-"
            
            # 变化量和样式
            if change > 0:
                change_str = f"+{format_size(change)}"
                change_class = "positive"
            elif change < 0:
                change_str = f"-{format_size(abs(change))}"
                change_class = "negative"
            else:
                change_str = "无变化"
                change_class = ""
            
            # 状态样式
            status_class = {
                "新增": "status-new",
                "修改": "status-modified",
                "删除": "status-deleted"
            }.get(status, "")
            
            html_content += f"""
                                <tr>
                                    <td class="file-path">{display_path}</td>
                                    <td>{old_size_str}</td>
                                    <td>{new_size_str}</td>
                                    <td class="file-change {change_class}">{change_str}</td>
                                    <td><span class="status-badge {status_class}">{status}</span></td>
                                </tr>"""
        
        total_files = len(type_files)
        shown_files = len(significant_files)
        
        html_content += f"""
                            </tbody>
                        </table>
                        {f'<p style="margin-top: 10px; color: #6c757d; font-size: 0.9em;">注: {file_type}类型共有 {total_files} 个文件，仅显示变化较大的 {shown_files} 个</p>' if total_files > shown_files else ''}
                    </div>
                </div>"""
    
    html_content += """
            </div>
        </div>"""
    
    if decreased_types:
        html_content += """
        <div class="resource-section">
            <h2>📉 减少的资源类型</h2>
            <p style="color: #6c757d; margin-bottom: 20px; font-style: italic;">以下显示各资源类型在IPA包中减少的体积大小（基于压缩后大小）</p>
            <div class="resource-list">"""
        
        # 生成可展开的减少资源类型
        for file_type, type_diff, old_size, new_size in decreased_types:
            # 计算真实大小变化
            real_old_size = old_by_type_uncompressed.get(file_type, 0)
            real_new_size = new_by_type_uncompressed.get(file_type, 0)
            real_diff = real_new_size - real_old_size
            
            type_files = files_by_type.get(file_type, [])
            significant_files = [f for f in type_files if abs(f['change']) >= 1024 or f['status'] in ['新增', '删除']]
            
            if len(significant_files) > 20:
                significant_files = significant_files[:20]
            
            html_content += f"""
                <div class="resource-item">
                    <div class="resource-header" onclick="toggleDetails(this)">
                        <span class="resource-name">
                            <span class="expand-icon">▶</span>
                            {file_type}
                        </span>
                        <div class="resource-change-container">
                            <span class="resource-change change-decrease ipa-badge">IPA -{format_size(abs(type_diff))}</span>
                            <span class="resource-change change-decrease real-badge">真实 -{format_size(abs(real_diff))}</span>
                        </div>
                    </div>
                    <div class="details-panel">
                        <table class="file-table">
                            <thead>
                                <tr>
                                    <th>文件路径</th>
                                    <th>旧版本大小</th>
                                    <th>新版本大小</th>
                                    <th>变化</th>
                                    <th>状态</th>
                                </tr>
                            </thead>
                            <tbody>"""
            
            for file_info in significant_files:
                file_path = file_info['path']
                old_size = file_info['old_size']
                new_size = file_info['new_size']
                change = file_info['change']
                status = file_info['status']
                
                # 同样的路径和大小格式化逻辑
                display_path = file_path
                if 'Framework' in display_path and len(display_path) > 40:
                    if '.framework/' in display_path:
                        parts = display_path.split('.framework/')
                        if len(parts) == 2:
                            framework_part = parts[0].split('/')[-1] + '.framework'
                            file_part = parts[1]
                            if len(file_part) > 25:
                                file_part = "..." + file_part[-22:]
                            display_path = f"{framework_part}/{file_part}"
                elif len(display_path) > 50:
                    display_path = "..." + display_path[-47:]
                
                old_size_str = format_size(old_size) if old_size > 0 else "-"
                new_size_str = format_size(new_size) if new_size > 0 else "-"
                
                if change > 0:
                    change_str = f"+{format_size(change)}"
                    change_class = "positive"
                elif change < 0:
                    change_str = f"-{format_size(abs(change))}"
                    change_class = "negative"
                else:
                    change_str = "无变化"
                    change_class = ""
                
                status_class = {
                    "新增": "status-new",
                    "修改": "status-modified", 
                    "删除": "status-deleted"
                }.get(status, "")
                
                html_content += f"""
                                <tr>
                                    <td class="file-path">{display_path}</td>
                                    <td>{old_size_str}</td>
                                    <td>{new_size_str}</td>
                                    <td class="file-change {change_class}">{change_str}</td>
                                    <td><span class="status-badge {status_class}">{status}</span></td>
                                </tr>"""
            
            total_files = len(type_files)
            shown_files = len(significant_files)
            
            html_content += f"""
                            </tbody>
                        </table>
                        {f'<p style="margin-top: 10px; color: #6c757d; font-size: 0.9em;">注: {file_type}类型共有 {total_files} 个文件，仅显示变化较大的 {shown_files} 个</p>' if total_files > shown_files else ''}
                    </div>
                </div>"""
        
        html_content += """
            </div>
        </div>"""
    
    html_content += f"""
        <div class="timestamp">
            报告生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        </div>
    </div>
</body>
</html>"""
    
    # 写入HTML文件
    with open(html_file_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    return str(html_file_path.absolute())

def find_ipa_file(directory):
    """在指定目录中查找第一个IPA文件"""
    directory = Path(directory)
    ipa_files = list(directory.glob("*.ipa"))
    if ipa_files:
        return ipa_files[0]
    return None

def main():
    """主函数"""
    current_dir = Path(__file__).parent
    old_dir = current_dir / "old"
    new_dir = current_dir / "new"
    result_file = current_dir / "result.txt"
    
    # 自动查找IPA文件
    old_ipa = find_ipa_file(old_dir)
    new_ipa = find_ipa_file(new_dir)
    
    # 检查文件是否存在
    if not old_ipa:
        print(f"错误: 在old目录中找不到IPA文件: {old_dir}")
        return
    
    if not new_ipa:
        print(f"错误: 在new目录中找不到IPA文件: {new_dir}")
        return
    
    print(f"找到旧版本IPA: {old_ipa.name}")
    print(f"找到新版本IPA: {new_ipa.name}")
    
    print("开始比较IPA文件...")
    
    try:
        # 执行比较
        report = compare_ipa_files(str(old_ipa), str(new_ipa))
        
        # 保存结果到文件
        with open(result_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"\n比较完成！结果已保存到: {result_file}")
        
        # 尝试自动打开HTML报告
        html_file = current_dir / "ipa_comparison_report.html"
        if html_file.exists():
            try:
                import subprocess
                import sys
                if sys.platform == "darwin":  # macOS
                    subprocess.run(["open", str(html_file)], check=False)
                    print(f"✅ 已在默认浏览器中打开HTML报告")
                elif sys.platform == "win32":  # Windows
                    subprocess.run(["start", str(html_file)], shell=True, check=False)
                    print(f"✅ 已在默认浏览器中打开HTML报告")
                elif sys.platform == "linux":  # Linux
                    subprocess.run(["xdg-open", str(html_file)], check=False)
                    print(f"✅ 已在默认浏览器中打开HTML报告")
            except Exception as e:
                print(f"⚠️  无法自动打开浏览器，请手动打开: {html_file}")
                print(f"   错误信息: {e}")
        
        print("\n" + "="*50)
        print("报告预览:")
        print("="*50)
        
        # 显示报告的前几行
        lines = report.split('\n')
        for i, line in enumerate(lines[:20]):  # 显示前20行
            print(line)
        
        if len(lines) > 20:
            print(f"\n... (完整报告共 {len(lines)} 行，请查看 result.txt 文件)")
            
    except Exception as e:
        print(f"比较过程中出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

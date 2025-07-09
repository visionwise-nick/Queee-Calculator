#!/usr/bin/env python3

import requests
import json
import time

BASE_URL = "https://queee-calculator-ai-backend-685339952769.us-central1.run.app"

def test_inheritance_functionality():
    print("🔧 测试AI设计师继承式修改功能")
    print("=" * 60)
    
    # 模拟现有配置（包含图像生成工坊的内容）
    current_config = {
        "id": "calc_scientific_test",
        "name": "科学计算器",
        "description": "测试用的科学计算器配置",
        "theme": {
            "name": "经典黑",
            "backgroundColor": "#000000",
            "displayBackgroundColor": "#222222",
            "displayTextColor": "#FFFFFF",
            "primaryButtonColor": "#333333",
            "secondaryButtonColor": "#555555",
            "operatorButtonColor": "#FF9F0A",
            "fontSize": 24.0,
            "buttonBorderRadius": 8.0
        },
        "layout": {
            "name": "科学计算器布局",
            "rows": 6,
            "columns": 6,
            "buttons": [
                {
                    "id": "btn_1",
                    "label": "1",
                    "action": {"type": "input", "value": "1"},
                    "gridPosition": {"row": 3, "column": 0},
                    "type": "primary",
                    "backgroundImage": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
                },
                {
                    "id": "btn_2",
                    "label": "2",
                    "action": {"type": "input", "value": "2"},
                    "gridPosition": {"row": 3, "column": 1},
                    "type": "primary"
                },
                {
                    "id": "btn_add",
                    "label": "+",
                    "action": {"type": "operator", "value": "+"},
                    "gridPosition": {"row": 3, "column": 2},
                    "type": "operator"
                },
                {
                    "id": "btn_equals",
                    "label": "=",
                    "action": {"type": "equals"},
                    "gridPosition": {"row": 4, "column": 0},
                    "type": "operator"
                }
            ]
        },
        "appBackground": {
            "backgroundImageUrl": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            "backgroundType": "image",
            "backgroundOpacity": 1.0,
            "buttonOpacity": 0.7,
            "displayOpacity": 0.8
        }
    }
    
    # 测试请求：只是简单添加一个sin函数
    test_request = {
        "user_input": "添加一个sin函数按钮",
        "current_config": current_config,
        "has_image_workshop_content": True,
        "workshop_protected_fields": [
            "appBackground.backgroundImageUrl",
            "appBackground.buttonOpacity",
            "appBackground.displayOpacity",
            "button.btn_1.backgroundImage"
        ]
    }
    
    print("📤 发送测试请求...")
    print(f"用户输入: {test_request['user_input']}")
    print(f"原配置按钮数量: {len(current_config['layout']['buttons'])}")
    print(f"保护字段数量: {len(test_request['workshop_protected_fields'])}")
    
    try:
        # 发送请求
        response = requests.post(
            f"{BASE_URL}/customize",
            json=test_request,
            headers={"Content-Type": "application/json"},
            timeout=120
        )
        
        if response.status_code == 200:
            result = response.json()
            print("\n✅ 请求成功！")
            
            # 分析结果
            print("\n📊 结果分析:")
            print(f"新配置ID: {result.get('id', 'N/A')}")
            print(f"新配置名称: {result.get('name', 'N/A')}")
            print(f"新配置描述: {result.get('description', 'N/A')}")
            
            # 检查按钮继承
            new_buttons = result.get('layout', {}).get('buttons', [])
            print(f"\n🔧 按钮继承检查:")
            print(f"新配置按钮数量: {len(new_buttons)}")
            
            # 检查原按钮是否保持
            original_button_ids = {btn['id'] for btn in current_config['layout']['buttons']}
            new_button_ids = {btn['id'] for btn in new_buttons}
            
            preserved_buttons = original_button_ids & new_button_ids
            new_buttons_only = new_button_ids - original_button_ids
            
            print(f"保持的按钮ID: {preserved_buttons}")
            print(f"新增的按钮ID: {new_buttons_only}")
            
            # 检查特定按钮的继承
            btn_1_old = next((btn for btn in current_config['layout']['buttons'] if btn['id'] == 'btn_1'), None)
            btn_1_new = next((btn for btn in new_buttons if btn['id'] == 'btn_1'), None)
            
            if btn_1_old and btn_1_new:
                print(f"\n🔍 btn_1 继承检查:")
                print(f"原标签: {btn_1_old['label']} -> 新标签: {btn_1_new['label']}")
                print(f"原背景图: {'存在' if btn_1_old.get('backgroundImage') else '无'} -> 新背景图: {'存在' if btn_1_new.get('backgroundImage') else '无'}")
                
                if btn_1_old.get('backgroundImage') == btn_1_new.get('backgroundImage'):
                    print("✅ 按钮背景图正确保持")
                else:
                    print("❌ 按钮背景图被修改了！")
            
            # 检查APP背景继承
            old_app_bg = current_config.get('appBackground', {})
            new_app_bg = result.get('appBackground', {})
            
            print(f"\n🎨 APP背景继承检查:")
            print(f"原背景图: {'存在' if old_app_bg.get('backgroundImageUrl') else '无'} -> 新背景图: {'存在' if new_app_bg.get('backgroundImageUrl') else '无'}")
            print(f"原按钮透明度: {old_app_bg.get('buttonOpacity', 'N/A')} -> 新按钮透明度: {new_app_bg.get('buttonOpacity', 'N/A')}")
            
            if old_app_bg.get('backgroundImageUrl') == new_app_bg.get('backgroundImageUrl'):
                print("✅ APP背景图正确保持")
            else:
                print("❌ APP背景图被修改了！")
                
            if old_app_bg.get('buttonOpacity') == new_app_bg.get('buttonOpacity'):
                print("✅ 按钮透明度正确保持")
            else:
                print("❌ 按钮透明度被修改了！")
            
            # 检查是否添加了sin函数
            sin_buttons = [btn for btn in new_buttons if 'sin' in btn['label'].lower()]
            if sin_buttons:
                print(f"\n🎯 sin函数检查:")
                print(f"找到sin按钮: {[btn['label'] for btn in sin_buttons]}")
                print("✅ 成功添加了sin函数按钮")
            else:
                print("❌ 没有找到sin函数按钮")
            
            print(f"\n📈 总结:")
            success_count = 0
            total_checks = 4
            
            if len(preserved_buttons) == len(original_button_ids):
                print("✅ 所有原按钮ID保持不变")
                success_count += 1
            else:
                print("❌ 部分原按钮ID被修改")
                
            if btn_1_old and btn_1_new and btn_1_old.get('backgroundImage') == btn_1_new.get('backgroundImage'):
                print("✅ 按钮背景图保护成功")
                success_count += 1
            else:
                print("❌ 按钮背景图保护失败")
                
            if old_app_bg.get('backgroundImageUrl') == new_app_bg.get('backgroundImageUrl'):
                print("✅ APP背景图保护成功")
                success_count += 1
            else:
                print("❌ APP背景图保护失败")
                
            if sin_buttons:
                print("✅ 新功能添加成功")
                success_count += 1
            else:
                print("❌ 新功能添加失败")
                
            print(f"\n🎉 测试结果: {success_count}/{total_checks} 项通过")
            
            if success_count == total_checks:
                print("🎊 完美！继承式修改功能工作正常！")
            elif success_count >= total_checks // 2:
                print("⚠️  部分功能正常，仍需改进")
            else:
                print("❌ 继承式修改功能存在问题")
                
        else:
            print(f"❌ 请求失败: {response.status_code}")
            print(f"错误详情: {response.text}")
            
    except requests.exceptions.Timeout:
        print("⏰ 请求超时")
    except Exception as e:
        print(f"❌ 请求异常: {e}")

if __name__ == "__main__":
    test_inheritance_functionality() 
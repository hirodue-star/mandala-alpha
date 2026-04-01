#!/usr/bin/env python3
"""
notify.py — Slack / Notion 自動通知ユーティリティ

使い方:
  python3 scripts/notify.py slack "メッセージ"
  python3 scripts/notify.py slack "メッセージ" --image /path/to/screenshot.png
  python3 scripts/notify.py notion --title "実装ログ" --body "内容"
  python3 scripts/notify.py check  # 設定状況チェック
"""

import os
import sys
import json
import base64
from pathlib import Path
from datetime import datetime

# ─── .env ロード ───────────────────────────────────────────

def load_env():
    env_path = Path(__file__).parent.parent / '.env'
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, _, val = line.partition('=')
                if val and key.strip() not in os.environ:
                    os.environ[key.strip()] = val.strip()

load_env()

SLACK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')
NOTION_TOKEN = os.environ.get('NOTION_API_TOKEN', '')
NOTION_DB = os.environ.get('NOTION_DATABASE_ID', '')

# ─── Slack ─────────────────────────────────────────────────

def send_slack(message: str, image_path: str = None) -> bool:
    if not SLACK_URL:
        print('⚠️  SLACK_WEBHOOK_URL が未設定です')
        print('   .env.example を参考に .env を作成してください')
        return False

    import urllib.request

    blocks = [
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": message}
        },
        {
            "type": "context",
            "elements": [
                {"type": "mrkdwn",
                 "text": f"🤖 マンダラα 自動通知 | {datetime.now().strftime('%Y-%m-%d %H:%M')}"}
            ]
        }
    ]

    payload = json.dumps({
        "text": message,
        "blocks": blocks,
    }).encode('utf-8')

    req = urllib.request.Request(
        SLACK_URL,
        data=payload,
        headers={'Content-Type': 'application/json'},
        method='POST',
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            if resp.status == 200:
                print(f'✅ Slack送信成功: {message[:50]}...')
                return True
            else:
                print(f'❌ Slack送信失敗: HTTP {resp.status}')
                return False
    except Exception as e:
        print(f'❌ Slack送信エラー: {e}')
        return False

# ─── Notion ────────────────────────────────────────────────

def append_notion(title: str, body: str, items: list = None, next_tasks: list = None) -> bool:
    if not NOTION_TOKEN or not NOTION_DB:
        print('⚠️  NOTION_API_TOKEN / NOTION_DATABASE_ID が未設定です')
        print('   .env.example を参考に .env を作成してください')
        return False

    import urllib.request

    children = [
        {
            "object": "block",
            "type": "paragraph",
            "paragraph": {
                "rich_text": [{"type": "text", "text": {"content": body}}]
            }
        }
    ]

    if items:
        children.append({
            "object": "block",
            "type": "heading_3",
            "heading_3": {
                "rich_text": [{"type": "text", "text": {"content": "実装項目"}}]
            }
        })
        for item in items:
            children.append({
                "object": "block",
                "type": "bulleted_list_item",
                "bulleted_list_item": {
                    "rich_text": [{"type": "text", "text": {"content": item}}]
                }
            })

    if next_tasks:
        children.append({
            "object": "block",
            "type": "heading_3",
            "heading_3": {
                "rich_text": [{"type": "text", "text": {"content": "次回の課題"}}]
            }
        })
        for task in next_tasks:
            children.append({
                "object": "block",
                "type": "to_do",
                "to_do": {
                    "rich_text": [{"type": "text", "text": {"content": task}}],
                    "checked": False,
                }
            })

    payload = json.dumps({
        "parent": {"database_id": NOTION_DB},
        "properties": {
            "マンダラα": {
                "title": [{"text": {"content": title}}]
            },
            "ステータス": {
                "status": {"name": "完了"}
            },
            "タグ": {
                "multi_select": [{"name": "開発ログ"}]
            },
        },
        "children": children,
    }).encode('utf-8')

    req = urllib.request.Request(
        'https://api.notion.com/v1/pages',
        data=payload,
        headers={
            'Authorization': f'Bearer {NOTION_TOKEN}',
            'Content-Type': 'application/json',
            'Notion-Version': '2022-06-28',
        },
        method='POST',
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status == 200:
                result = json.loads(resp.read())
                print(f'✅ Notion追記成功: {title} → {result.get("url", "")}')
                return True
            else:
                print(f'❌ Notion追記失敗: HTTP {resp.status}')
                return False
    except Exception as e:
        print(f'❌ Notionエラー: {e}')
        return False

# ─── 設定チェック ──────────────────────────────────────────

def check_setup():
    print('=' * 50)
    print('🔧 マンダラα 外部連携 設定状況')
    print('=' * 50)

    checks = [
        ('Slack Webhook', SLACK_URL),
        ('Notion Token', NOTION_TOKEN),
        ('Notion DB ID', NOTION_DB),
        ('Anthropic Key', os.environ.get('ANTHROPIC_API_KEY', '')),
        ('OpenAI Key', os.environ.get('OPENAI_API_KEY', '')),
    ]

    all_ok = True
    for name, val in checks:
        if val:
            masked = val[:8] + '...' + val[-4:] if len(val) > 12 else '***'
            print(f'  ✅ {name}: {masked}')
        else:
            print(f'  ❌ {name}: 未設定')
            all_ok = False

    print()
    if not all_ok:
        print('📋 設定手順:')
        print('  1. cp .env.example .env')
        print('  2. .env を編集して各キーを入力')
        print('  3. python3 scripts/notify.py check で再確認')
    else:
        print('🎉 全サービス連携準備完了!')
    print()

# ─── Git Auto Push ─────────────────────────────────────────

def git_auto_push(message: str = None) -> bool:
    import subprocess

    if not message:
        message = f'auto: session update {datetime.now().strftime("%Y-%m-%d %H:%M")}'

    try:
        # ステージング
        subprocess.run(['git', 'add', '-A'], cwd=str(Path(__file__).parent.parent),
                       check=True, capture_output=True)
        # コミット
        result = subprocess.run(
            ['git', 'commit', '-m', message],
            cwd=str(Path(__file__).parent.parent),
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            if 'nothing to commit' in result.stdout:
                print('ℹ️  コミット対象なし')
                return True
            print(f'❌ git commit 失敗: {result.stderr}')
            return False

        # プッシュ
        result = subprocess.run(
            ['git', 'push', 'origin', 'main'],
            cwd=str(Path(__file__).parent.parent),
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            print(f'✅ GitHub push 成功: {message[:50]}')
            return True
        else:
            print(f'❌ git push 失敗: {result.stderr}')
            return False
    except Exception as e:
        print(f'❌ Git エラー: {e}')
        return False

# ─── CLI ───────────────────────────────────────────────────

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('使い方: python3 scripts/notify.py [slack|notion|check|push] ...')
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == 'check':
        check_setup()

    elif cmd == 'slack':
        msg = sys.argv[2] if len(sys.argv) > 2 else '疎通テスト: マンダラα自動通知システム稼働中 🐣'
        send_slack(msg)

    elif cmd == 'notion':
        title = 'セッションログ'
        body = '自動生成されたログ'
        for i, arg in enumerate(sys.argv):
            if arg == '--title' and i + 1 < len(sys.argv):
                title = sys.argv[i + 1]
            if arg == '--body' and i + 1 < len(sys.argv):
                body = sys.argv[i + 1]
        append_notion(title, body)

    elif cmd == 'push':
        msg = sys.argv[2] if len(sys.argv) > 2 else None
        git_auto_push(msg)

    else:
        print(f'不明なコマンド: {cmd}')
        sys.exit(1)

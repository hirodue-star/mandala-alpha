#!/usr/bin/env python3
"""
slack_commander.py — Slackリモート司令塔

Slackチャンネルからのテキスト指示を監視し、
自動でコード修正・ビルド・再起動を行う常駐プロセス。

使い方:
  python3 scripts/slack_commander.py

必要な環境変数(.env):
  SLACK_BOT_TOKEN  — Slack Bot User OAuth Token (xoxb-...)
  SLACK_CHANNEL_ID — 監視するチャンネルID (C...)

※ Incoming Webhook では受信不可。Bot Token が必要です。
"""

import os
import sys
import json
import time
import subprocess
from pathlib import Path
from datetime import datetime

PROJECT_DIR = Path(__file__).parent.parent

# ─── .env ロード ───────────────────────────────────────────

def load_env():
    env_path = PROJECT_DIR / '.env'
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, _, val = line.partition('=')
                if val and key.strip() not in os.environ:
                    os.environ[key.strip()] = val.strip()

load_env()

BOT_TOKEN = os.environ.get('SLACK_BOT_TOKEN', '')
CHANNEL_ID = os.environ.get('SLACK_CHANNEL_ID', '')
WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')

# ─── コマンドマッピング ────────────────────────────────────

COMMANDS = {
    'ビルド':       'flutter build web --release',
    'リスタート':   'scripts/serve_preview.py',
    'ステータス':   'flutter analyze --no-pub 2>&1 | tail -5',
    'スクショ':     'xcrun simctl io booted screenshot tmp/remote_capture.png',
}

COLOR_MAP = {
    'あか': '0xFFFF5252', 'あお': '0xFF42A5F5', 'みどり': '0xFF66BB6A',
    'きいろ': '0xFFFFEE58', 'ピンク': '0xFFEC407A', 'むらさき': '0xFF7E57C2',
    'オレンジ': '0xFFFF7043', 'しろ': '0xFFFFFFFF',
}

def send_reply(message: str):
    """Slack Webhook で返信"""
    if not WEBHOOK_URL:
        print(f'  → {message}')
        return
    import urllib.request
    payload = json.dumps({'text': f'🤖 *司令塔:* {message}'}).encode()
    req = urllib.request.Request(WEBHOOK_URL, data=payload,
        headers={'Content-Type': 'application/json'}, method='POST')
    try:
        urllib.request.urlopen(req, timeout=5)
    except Exception:
        pass

def handle_command(text: str):
    """テキスト指示を解析して実行"""
    original = text.strip()
    text = original.lower()
    print(f'📩 受信: {text[:80]}')

    # ─── Gemini/外部AI 指示形式の検知 ──────────────────
    # 「# 【MA-LOGIC：...」形式 → コマンドファイルに書き込み、Claude Code に委譲
    if '【ma-logic' in text or '【ma-logic' in original:
        send_reply('🤖 外部AI指示を検知！Claude Codeへ転送中...')
        cmd_file = PROJECT_DIR / 'tmp' / 'ai_directive.txt'
        cmd_file.write_text(original)
        send_reply(f'📋 指示を `tmp/ai_directive.txt` に保存しました。\n次回のClaude Codeセッションで自動実行されます。')
        # session-handoff も実行して記録
        subprocess.run(['python3', 'session-handoff.py'], cwd=str(PROJECT_DIR),
                       capture_output=True)
        return True

    # 色変更指示
    for color_name, color_code in COLOR_MAP.items():
        if color_name in text and ('プピィ' in text or 'ぷぴぃ' in text or '色' in text):
            send_reply(f'プピィの色を{color_name}に変更中...')
            # TODO: puppy_character.dart の _gradColors を書き換え
            send_reply(f'⚠️ 色変更は手動対応が必要です（{color_name} → {color_code}）')
            return True

    # 定型コマンド
    for keyword, cmd in COMMANDS.items():
        if keyword in text:
            send_reply(f'`{keyword}` を実行中...')
            try:
                result = subprocess.run(cmd, shell=True, capture_output=True,
                    text=True, timeout=120, cwd=str(PROJECT_DIR))
                output = result.stdout[-200:] if result.stdout else result.stderr[-200:]
                send_reply(f'`{keyword}` 完了:\n```{output}```')
            except Exception as e:
                send_reply(f'❌ エラー: {e}')
            return True

    # ハンドオフ
    if 'ハンドオフ' in text or 'handoff' in text:
        send_reply('session-handoff.py を実行中...')
        subprocess.run(['python3', 'session-handoff.py'], cwd=str(PROJECT_DIR))
        send_reply('✅ ハンドオフ完了')
        return True

    return False

# ─── Slack API ポーリング ──────────────────────────────────

def poll_slack():
    """Slack API で新しいメッセージを取得"""
    if not BOT_TOKEN or not CHANNEL_ID:
        return []
    import urllib.request
    req = urllib.request.Request(
        f'https://slack.com/api/conversations.history?channel={CHANNEL_ID}&limit=3',
        headers={'Authorization': f'Bearer {BOT_TOKEN}'},
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            if data.get('ok'):
                return data.get('messages', [])
    except Exception:
        pass
    return []

# ─── ファイル監視モード（Bot Token不要） ──────────────────

COMMAND_FILE = PROJECT_DIR / 'tmp' / 'remote_command.txt'

def poll_file():
    """ファイルベースのコマンド受信（Bot Token不要の代替手段）"""
    if COMMAND_FILE.exists():
        text = COMMAND_FILE.read_text().strip()
        if text:
            COMMAND_FILE.write_text('')  # クリア
            return text
    return None

# ─── メインループ ─────────────────────────────────────────

def main():
    print('=' * 50)
    print('🎮 マンダラα Slackリモート司令塔')
    print('=' * 50)

    if BOT_TOKEN and CHANNEL_ID:
        print(f'📡 モード: Slack API ポーリング')
        print(f'📢 チャンネル: {CHANNEL_ID}')
    else:
        print(f'📁 モード: ファイル監視 ({COMMAND_FILE})')
        print(f'⚠️  Slack APIポーリングには SLACK_BOT_TOKEN と SLACK_CHANNEL_ID が必要です')
        print(f'   .env に追加してください')
        os.makedirs(COMMAND_FILE.parent, exist_ok=True)
        COMMAND_FILE.write_text('')

    send_reply('司令塔が起動しました！指示をお待ちしています 🫡')
    print('\n🟢 監視中... (Ctrl+C で停止)\n')

    last_ts = str(time.time())

    while True:
        try:
            if BOT_TOKEN and CHANNEL_ID:
                messages = poll_slack()
                for msg in messages:
                    ts = msg.get('ts', '0')
                    if float(ts) > float(last_ts) and not msg.get('bot_id'):
                        handle_command(msg.get('text', ''))
                        last_ts = ts
            else:
                cmd = poll_file()
                if cmd:
                    handle_command(cmd)

            time.sleep(5)
        except KeyboardInterrupt:
            print('\n🔴 司令塔停止')
            send_reply('司令塔を停止しました')
            break
        except Exception as e:
            print(f'⚠️  エラー: {e}')
            time.sleep(10)


if __name__ == '__main__':
    main()

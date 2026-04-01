#!/usr/bin/env python3
"""
github_watcher.py — GitHub Issue 自動監視

「指示」ラベルのIssueを60秒ごとにチェック。
検知したら tmp/ai_directive.txt に保存し、Slackに通知。
次回のClaude Codeセッションで自動実行される。

前提: gh auth login 済み

使い方:
  nohup python3 scripts/github_watcher.py > /tmp/mandala_gh_watcher.log 2>&1 &
"""

import subprocess
import json
import time
import os
import sys
from pathlib import Path
from datetime import datetime

PROJECT_DIR = Path(__file__).parent.parent
DIRECTIVE_FILE = PROJECT_DIR / 'tmp' / 'ai_directive.txt'
PROCESSED_FILE = PROJECT_DIR / 'tmp' / 'processed_issues.txt'

def load_env():
    env_path = PROJECT_DIR / '.env'
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, _, v = line.partition('=')
                if v and k.strip() not in os.environ:
                    os.environ[k.strip()] = v.strip()

load_env()

def send_slack(msg):
    sys.path.insert(0, str(PROJECT_DIR / 'scripts'))
    try:
        from notify import send_slack as _send
        _send(msg)
    except Exception:
        pass

def get_processed():
    if PROCESSED_FILE.exists():
        return set(PROCESSED_FILE.read_text().strip().split('\n'))
    return set()

def mark_processed(number):
    processed = get_processed()
    processed.add(str(number))
    PROCESSED_FILE.write_text('\n'.join(processed))

def check_issues():
    try:
        result = subprocess.run(
            ['gh', 'issue', 'list', '--label', '指示', '--state', 'open',
             '--limit', '5', '--json', 'number,title,body'],
            capture_output=True, text=True, timeout=30,
            cwd=str(PROJECT_DIR),
        )
        if result.returncode != 0:
            return []
        return json.loads(result.stdout) if result.stdout.strip() else []
    except Exception as e:
        print(f'⚠️ Issue取得エラー: {e}')
        return []

def close_issue(number):
    try:
        subprocess.run(
            ['gh', 'issue', 'close', str(number), '--comment',
             '✅ Claude Codeが検知しました。次回セッションで自動実行されます。'],
            capture_output=True, timeout=15,
            cwd=str(PROJECT_DIR),
        )
        print(f'  ✅ Issue #{number} クローズ')
    except Exception as e:
        print(f'  ⚠️ クローズ失敗: {e}')

def main():
    print('=' * 50)
    print('👁️ GitHub Issue 自動監視')
    print(f'📂 プロジェクト: {PROJECT_DIR}')
    print(f'🏷️ 監視ラベル: "指示"')
    print('=' * 50)

    send_slack('👁️ *GitHub Issue 自動監視を起動しました*\n「指示」ラベルのIssueを60秒ごとにチェックします')

    processed = get_processed()

    while True:
        try:
            issues = check_issues()
            for issue in issues:
                num = str(issue['number'])
                if num in processed:
                    continue

                title = issue.get('title', '')
                body = issue.get('body', '')
                print(f'\n🆕 Issue #{num}: {title}')

                # 指示ファイルに保存
                directive = f"# GitHub Issue #{num}: {title}\n{body}"
                os.makedirs(DIRECTIVE_FILE.parent, exist_ok=True)
                DIRECTIVE_FILE.write_text(directive)

                # Slack通知
                send_slack(
                    f'🆕 *GitHub Issue検知！*\n'
                    f'#{num}: {title}\n'
                    f'```{body[:300]}```\n'
                    f'📋 → tmp/ai_directive.txt に保存済み\n'
                    f'次回Claude Codeセッションで自動実行されます'
                )

                # Issueクローズ
                close_issue(issue['number'])
                mark_processed(num)

            time.sleep(60)
        except KeyboardInterrupt:
            print('\n🔴 監視停止')
            break
        except Exception as e:
            print(f'⚠️ エラー: {e}')
            time.sleep(60)

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
github_watcher.py — GitHub Issue 自動監視 + Skill インストーラー

「指示」ラベルのIssueを60秒ごとにチェック。
検知したら tmp/ai_directive.txt に保存し、Slackに通知。
次回のClaude Codeセッションで自動実行される。

--install-skill: GitHub Gist から Skill 定義を取得し、
  --target-module で指定したモジュールに適用する。

前提: gh auth login 済み

使い方:
  nohup python3 scripts/github_watcher.py > /tmp/mandala_gh_watcher.log 2>&1 &
  python3 scripts/github_watcher.py --install-skill <gist_url_or_id> --target-module "名前"
"""

import subprocess
import json
import time
import os
import sys
import argparse
from pathlib import Path
from datetime import datetime

PROJECT_DIR = Path(__file__).parent.parent
DIRECTIVE_FILE = PROJECT_DIR / 'tmp' / 'ai_directive.txt'
PROCESSED_FILE = PROJECT_DIR / 'tmp' / 'processed_issues.txt'
SKILLS_DIR = PROJECT_DIR / 'tmp' / 'skills'

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

# ─── install-skill ────────────────────────────────────────

def extract_gist_id(url_or_id):
    """URL or raw Gist ID → Gist ID"""
    s = url_or_id.strip().rstrip('/')
    return s.split('/')[-1]

def fetch_gist(gist_id):
    """gh gist view でGistの内容を取得"""
    result = subprocess.run(
        ['gh', 'gist', 'view', gist_id, '--raw'],
        capture_output=True, text=True, timeout=30,
    )
    if result.returncode != 0:
        print(f'❌ Gist取得失敗: {result.stderr}')
        sys.exit(1)
    return result.stdout

def install_skill(gist_url_or_id, target_module=None):
    """GistからSkillを取得し、ローカルに保存"""
    gist_id = extract_gist_id(gist_url_or_id)
    print(f'📥 Gist取得中: {gist_id}')

    content = fetch_gist(gist_id)
    if not content.strip():
        print('❌ Gistが空です')
        sys.exit(1)

    # スキルをファイルに保存
    os.makedirs(SKILLS_DIR, exist_ok=True)
    skill_file = SKILLS_DIR / f'{gist_id}.md'
    skill_file.write_text(content)
    print(f'✅ Skill保存: {skill_file}')

    # メタデータ抽出
    name = gist_id
    for line in content.splitlines():
        if line.strip().startswith('name:'):
            name = line.split(':', 1)[1].strip()
            break

    # インストール記録
    manifest_file = SKILLS_DIR / 'manifest.json'
    manifest = []
    if manifest_file.exists():
        try:
            manifest = json.loads(manifest_file.read_text())
        except Exception:
            manifest = []

    manifest.append({
        'gist_id': gist_id,
        'name': name,
        'target_module': target_module,
        'installed_at': datetime.now().isoformat(),
        'file': str(skill_file),
    })
    manifest_file.write_text(json.dumps(manifest, indent=2, ensure_ascii=False))

    print(f'📋 Skill名: {name}')
    if target_module:
        print(f'🎯 適用先: {target_module}')

    # Slack通知
    send_slack(
        f'📥 *Skill インストール完了*\n'
        f'• Skill: {name}\n'
        f'• Gist: `{gist_id}`\n'
        f'• 適用先: {target_module or "(未指定)"}\n'
        f'• 保存先: `{skill_file.relative_to(PROJECT_DIR)}`'
    )

    return content, name

# ─── メイン ───────────────────────────────────────────────

def watch_loop():
    """Issue監視ループ"""
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

def main():
    parser = argparse.ArgumentParser(
        description='GitHub Issue 自動監視 + Skill インストーラー')
    parser.add_argument('--install-skill',
        metavar='GIST_URL_OR_ID',
        help='GitHub GistからSkillを取得してインストール')
    parser.add_argument('--target-module',
        metavar='MODULE_NAME',
        help='Skillの適用先モジュール名')
    parser.add_argument('--list-skills',
        action='store_true',
        help='インストール済みSkill一覧を表示')
    parser.add_argument('--execute-all',
        action='store_true',
        help='未処理Issueを一括チェック（ループなし）')

    args = parser.parse_args()

    if args.list_skills:
        manifest_file = SKILLS_DIR / 'manifest.json'
        if not manifest_file.exists():
            print('📭 インストール済みSkillはありません')
            return
        manifest = json.loads(manifest_file.read_text())
        for i, s in enumerate(manifest, 1):
            print(f'  {i}. {s["name"]} → {s.get("target_module", "(未指定)")}  [{s["gist_id"][:8]}...]')
        return

    if args.install_skill:
        content, name = install_skill(args.install_skill, args.target_module)
        print(f'\n✅ インストール完了: {name}')
        if args.target_module:
            print(f'🎯 --target-module "{args.target_module}" を適用します')
        return

    if args.execute_all:
        issues = check_issues()
        processed = get_processed()
        found = 0
        for issue in issues:
            num = str(issue['number'])
            if num in processed:
                continue
            found += 1
            title = issue.get('title', '')
            body = issue.get('body', '')
            print(f'🆕 Issue #{num}: {title}')
            directive = f"# GitHub Issue #{num}: {title}\n{body}"
            os.makedirs(DIRECTIVE_FILE.parent, exist_ok=True)
            DIRECTIVE_FILE.write_text(directive)
            close_issue(issue['number'])
            mark_processed(num)
        if found == 0:
            print('✅ 未処理のIssueはありません')
        return

    # デフォルト: 監視ループ
    watch_loop()

if __name__ == '__main__':
    main()

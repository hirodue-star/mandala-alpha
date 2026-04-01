#!/usr/bin/env python3
"""
session-handoff.py
マンダラα：セッション終了時に実行。メモリ保存 + Slack/Notion自動通知。
"""
import subprocess
import datetime
import os
import sys
import json

MEMORY_DIR = os.path.expanduser("~/.claude/projects/-Users-hiroki/memory")
HANDOFF_FILE = os.path.join(MEMORY_DIR, "last_session.json")
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))


def run(cmd: str) -> str:
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT).strip()
    except subprocess.CalledProcessError as e:
        return e.output.strip()


def collect_state() -> dict:
    now = datetime.datetime.now().isoformat()

    git_log = run(f"git -C {PROJECT_DIR} log --oneline -5")
    git_branch = run(f"git -C {PROJECT_DIR} branch --show-current")
    build_result = run(
        f"ls -la {PROJECT_DIR}/build/ios/iphoneos/Runner.app 2>/dev/null | head -1"
    )
    screens = run(f"ls {PROJECT_DIR}/lib/screens/")
    flutter_ver = run("flutter --version 2>&1 | head -1")

    # スクリーンショット一覧
    screenshots = run(f"ls {PROJECT_DIR}/tmp/*.png 2>/dev/null").split("\n") if os.path.isdir(f"{PROJECT_DIR}/tmp") else []

    return {
        "timestamp": now,
        "project_dir": PROJECT_DIR,
        "flutter_version": flutter_ver,
        "git_branch": git_branch,
        "recent_commits": git_log,
        "ios_build": "SUCCESS" if "Runner.app" in build_result else "NOT_FOUND",
        "screens": [s for s in screens.split("\n") if s],
        "screenshots": [s for s in screenshots if s],
        "next_tasks": [
            "GitHub push (hirodue-star/mandala-alpha)",
            "TestFlight ビルド",
            "RevenueCat 課金導線実装",
            "App Store Connect メタデータ準備",
        ],
    }


def save(state: dict):
    os.makedirs(MEMORY_DIR, exist_ok=True)
    with open(HANDOFF_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)
    print(f"✅ ハンドオフ保存: {HANDOFF_FILE}")


def print_summary(state: dict):
    print("\n" + "=" * 50)
    print("🔁 セッションハンドオフ サマリー")
    print("=" * 50)
    print(f"📅 日時       : {state['timestamp']}")
    print(f"🌿 ブランチ   : {state['git_branch']}")
    print(f"📱 iOSビルド  : {state['ios_build']}")
    print(f"\n📝 最近のコミット:\n{state['recent_commits']}")
    print(f"\n📁 実装済み画面 ({len(state['screens'])}):")
    for s in state["screens"]:
        print(f"  {s}")
    if state["screenshots"]:
        print(f"\n📸 スクリーンショット ({len(state['screenshots'])}):")
        for s in state["screenshots"]:
            print(f"  {os.path.basename(s)}")
    print("\n🎯 次のタスク:")
    for i, t in enumerate(state["next_tasks"], 1):
        print(f"  {i}. {t}")
    print("=" * 50)


# ─── 外部サービス連携 ──────────────────────────────────────

def notify_slack(state: dict):
    """Slack に完了報告を送信"""
    try:
        sys.path.insert(0, os.path.join(PROJECT_DIR, 'scripts'))
        from notify import send_slack, SLACK_URL
        if not SLACK_URL:
            return
        msg = (
            f"*🔁 マンダラα セッション完了*\n"
            f"📅 {state['timestamp'][:16]}\n"
            f"📁 画面数: {len(state['screens'])}\n"
            f"📝 最新コミット:\n```{state['recent_commits']}```\n"
            f"🎯 次: {state['next_tasks'][0] if state['next_tasks'] else 'なし'}"
        )
        send_slack(msg)
    except Exception as e:
        print(f"⚠️  Slack通知スキップ: {e}")


def notify_notion(state: dict):
    """Notion に開発ログを追記"""
    try:
        sys.path.insert(0, os.path.join(PROJECT_DIR, 'scripts'))
        from notify import append_notion, NOTION_TOKEN, NOTION_DB
        if not NOTION_TOKEN or not NOTION_DB:
            return
        items = [f"画面: {s}" for s in state['screens'][:5]]
        append_notion(
            title=f"セッション {state['timestamp'][:10]}",
            body=f"最新コミット:\n{state['recent_commits']}",
            items=items,
            next_tasks=state['next_tasks'],
        )
    except Exception as e:
        print(f"⚠️  Notion通知スキップ: {e}")


# ─── メイン ────────────────────────────────────────────────

if __name__ == "__main__":
    state = collect_state()
    save(state)
    print_summary(state)

    # 外部連携（キー未設定なら静かにスキップ）
    print()
    notify_slack(state)
    notify_notion(state)

#!/usr/bin/env python3
"""
session-handoff.py
マンダラα：セッション終了時に実行し、記憶・状態をメモリに保存する。
"""
import subprocess
import datetime
import os
import json

MEMORY_DIR = os.path.expanduser("~/.claude/projects/-Users-hiroki/memory")
HANDOFF_FILE = os.path.join(MEMORY_DIR, "last_session.json")


def run(cmd: str) -> str:
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT).strip()
    except subprocess.CalledProcessError as e:
        return e.output.strip()


def collect_state() -> dict:
    now = datetime.datetime.now().isoformat()
    project_dir = os.path.dirname(os.path.abspath(__file__))

    git_log = run(f"git -C {project_dir} log --oneline -5")
    git_branch = run(f"git -C {project_dir} branch --show-current")
    build_result = run(
        f"ls -la {project_dir}/build/ios/iphoneos/Runner.app 2>/dev/null | head -1"
    )
    screens = run(f"ls {project_dir}/lib/screens/")
    flutter_ver = run("flutter --version 2>&1 | head -1")

    return {
        "timestamp": now,
        "project_dir": project_dir,
        "flutter_version": flutter_ver,
        "git_branch": git_branch,
        "recent_commits": git_log,
        "ios_build": "SUCCESS" if "Runner.app" in build_result else "NOT_FOUND",
        "screens": screens.split("\n"),
        "next_tasks": [
            "GitHub push (hirodue-star/mandala-alpha)",
            "MandalaChartScreen: シミュレータ動作確認",
            "FlutterFlowプロジェクトへ MandalaChartScreen を移植",
            "RevenueCat 課金導線実装",
            "TestFlight ビルド",
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
    print(f"\n📁 実装済み画面:\n  " + "\n  ".join(state["screens"]))
    print("\n🎯 次のタスク:")
    for i, t in enumerate(state["next_tasks"], 1):
        print(f"  {i}. {t}")
    print("=" * 50 + "\n")


if __name__ == "__main__":
    state = collect_state()
    save(state)
    print_summary(state)

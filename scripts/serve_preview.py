#!/usr/bin/env python3
"""
serve_preview.py — Flutter Web プレビューサーバー＋QRコード発行

使い方:
  python3 scripts/serve_preview.py          # サーバー起動+QR生成+Slack送信
  python3 scripts/serve_preview.py --port 8080
"""

import http.server
import socketserver
import socket
import os
import sys
import threading
from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent
WEB_DIR = PROJECT_DIR / 'build' / 'web'
QR_PATH = PROJECT_DIR / 'tmp' / 'preview_qr.png'
PORT = 3000


def get_local_ip():
    """ローカルネットワークIPを取得"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    except Exception:
        return '127.0.0.1'
    finally:
        s.close()


def generate_qr(url: str):
    """QRコード画像を生成"""
    try:
        import qrcode
        qr = qrcode.QRCode(version=1, box_size=10, border=2)
        qr.add_data(url)
        qr.make(fit=True)
        img = qr.make_image(fill_color='#5A4A3A', back_color='#FFF8E7')
        os.makedirs(QR_PATH.parent, exist_ok=True)
        img.save(str(QR_PATH))
        print(f'📱 QRコード生成: {QR_PATH}')
        return True
    except ImportError:
        print('⚠️  qrcode モジュール未インストール: pip3 install qrcode[pil]')
        return False


def notify_slack(url: str):
    """SlackにプレビューURLを通知"""
    sys.path.insert(0, str(PROJECT_DIR / 'scripts'))
    try:
        from notify import send_slack, SLACK_URL
        if SLACK_URL:
            send_slack(
                f'📱 *iPhone プレビュー準備完了！*\n\n'
                f'🌐 URL: {url}\n'
                f'📷 QRコード: tmp/preview_qr.png\n\n'
                f'iPhoneのブラウザで上記URLを開くか、\n'
                f'QRコードをカメラでスキャンしてください！\n\n'
                f'💡 同じWi-Fiに接続していることを確認'
            )
    except Exception as e:
        print(f'⚠️  Slack通知スキップ: {e}')


def start_server(port: int):
    """Flutter Web をローカルネットワークに公開"""
    if not WEB_DIR.exists():
        print('❌ build/web が見つかりません。flutter build web を実行してください。')
        sys.exit(1)

    os.chdir(str(WEB_DIR))

    handler = http.server.SimpleHTTPRequestHandler
    handler.extensions_map.update({
        '.dart': 'application/javascript',
        '.wasm': 'application/wasm',
    })

    with socketserver.TCPServer(('0.0.0.0', port), handler) as httpd:
        ip = get_local_ip()
        url = f'http://{ip}:{port}'

        print()
        print('=' * 50)
        print('📱 マンダラα iPhone プレビューサーバー')
        print('=' * 50)
        print(f'🌐 URL:       {url}')
        print(f'🏠 ローカル:  http://localhost:{port}')
        print(f'📂 配信元:    {WEB_DIR}')
        print()

        # QRコード生成
        generate_qr(url)

        # Slack通知
        notify_slack(url)

        print()
        print('🟢 サーバー稼働中... (Ctrl+C で停止)')
        print()

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\n🔴 サーバー停止')


if __name__ == '__main__':
    port = PORT
    for i, arg in enumerate(sys.argv):
        if arg == '--port' and i + 1 < len(sys.argv):
            port = int(sys.argv[i + 1])

    start_server(port)

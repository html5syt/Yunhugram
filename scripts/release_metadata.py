"""解析 tag 或约定式提交中的发布元数据，不读取或输出签名密钥值。"""
import json
import os
import re
import subprocess
from pathlib import Path

TAG = re.compile(r"^v(\d+\.\d+\.\d+)$")
META = re.compile(r'\[release\s+ver\s*=\s*"?(v\d+\.\d+\.\d+)"?\s*,\s*pre\s*=\s*(true|false)\s*,\s*draft\s*=\s*(true|false)\]')


def resolve(ref: str, message: str, manual: str = "") -> dict[str, str]:
    """不含发布标记的普通提交只执行调试检查，不创建 Release。"""
    tag = manual or (ref.removeprefix("refs/tags/") if ref.startswith("refs/tags/") else "")
    pre, draft = "false", "false"
    match = META.search(message)
    if not tag and match:
        tag, pre, draft = match.groups()
    version = TAG.fullmatch(tag)
    if tag and not version:
        raise ValueError("发布 tag 必须为 vX.Y.Z")
    return {"release": str(bool(version)).lower(), "tag": tag, "version": version[1] if version else "", "prerelease": pre, "draft": draft}


def main() -> None:
    message = subprocess.check_output(["git", "log", "-1", "--format=%B"], encoding="utf-8")
    data = resolve(os.environ.get("GITHUB_REF", ""), message, os.environ.get("MANUAL_TAG", ""))
    data["sha"] = subprocess.check_output(["git", "rev-parse", "HEAD"], encoding="utf-8").strip()
    data["android_signed"] = str(all(os.environ.get(k) for k in ("ANDROID_KEYSTORE_BASE64", "ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD"))).lower()
    if data["release"] == "true":
        declared = re.search(r"^version:\s*(\S+)", Path("pubspec.yaml").read_text(encoding="utf-8"), re.M)[1].split("+")[0]
        if declared != data["version"]:
            raise ValueError("tag 与应用版本不同，停止发布")
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as stream:
            stream.write("".join(f"{key}={value}\n" for key, value in data.items()))
    print(json.dumps(data, ensure_ascii=False))


if __name__ == "__main__":
    main()

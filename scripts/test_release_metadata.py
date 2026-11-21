"""发布条件的轻量检查，不需要任何真实密钥。"""
import unittest
from release_metadata import resolve


class ReleaseMetadataTests(unittest.TestCase):
    def test_regular_commit_is_not_release(self):
        self.assertEqual(resolve("refs/heads/main", "feat: 登录")["release"], "false")

    def test_tag_release(self):
        self.assertEqual(resolve("refs/tags/v0.1.0", "发布")["version"], "0.1.0")

    def test_commit_metadata(self):
        data = resolve("refs/heads/main", 'chore: 发布 [release ver="v0.1.0", pre=false, draft=true]')
        self.assertEqual(data["tag"], "v0.1.0")
        self.assertEqual(data["draft"], "true")

    def test_invalid_manual_tag_is_rejected(self):
        with self.assertRaises(ValueError):
            resolve("refs/heads/main", "", "latest")


if __name__ == "__main__":
    unittest.main()

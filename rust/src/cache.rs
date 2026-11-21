//! 按账号隔离的列表缓存；绝不保存登录凭据。
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{collections::BTreeMap, path::PathBuf};

#[derive(Default, Serialize, Deserialize)]
pub struct Cache {
    pub owner: String,
    pub entries: BTreeMap<String, Entry>,
    #[serde(skip)]
    pub path: PathBuf,
}
#[derive(Clone, Serialize, Deserialize)]
pub struct Entry {
    pub md5: String,
    pub data: Value,
}
impl Cache {
    pub fn open(directory: &str) -> Self {
        let path = PathBuf::from(directory).join("yhlib-cache.json");
        let mut cache = std::fs::read(&path)
            .ok()
            .and_then(|b| serde_json::from_slice::<Self>(&b).ok())
            .unwrap_or_default();
        cache.path = path;
        cache
    }
    pub fn set_owner(&mut self, owner: &str) {
        if self.owner != owner {
            self.entries.clear();
            self.owner = owner.to_owned();
        }
    }
    pub fn hash(&self, key: &str) -> String {
        self.entries
            .get(key)
            .map(|e| e.md5.clone())
            .unwrap_or_default()
    }
    /// 仅请求了相同摘要时，空列表代表“没有变化”；否则空列表是有效结果。
    pub fn merge(&mut self, key: &str, requested: &str, md5: String, data: Value) -> Value {
        if !requested.is_empty()
            && requested == md5
            && data.as_array().is_some_and(|a| a.is_empty())
            && let Some(e) = self.entries.get(key)
        {
            return e.data.clone();
        }
        self.entries.insert(
            key.to_owned(),
            Entry {
                md5,
                data: data.clone(),
            },
        );
        data
    }
    pub fn save(&self) -> std::io::Result<()> {
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let bytes = serde_json::to_vec(self).map_err(std::io::Error::other)?;
        let temporary = self.path.with_extension("tmp");
        std::fs::write(&temporary, bytes)?;
        std::fs::rename(temporary, &self.path)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    #[test]
    fn unchanged_empty_list_keeps_existing_cache() {
        let mut c = Cache::default();
        c.merge("chats", "", "a".into(), json!([{"chatId":"1"}]));
        assert_eq!(
            c.merge("chats", "a", "a".into(), json!([])),
            json!([{"chatId":"1"}])
        );
        assert_eq!(c.merge("chats", "a", "b".into(), json!([])), json!([]));
    }
    #[test]
    fn a_different_account_cannot_read_previous_contacts() {
        let mut c = Cache::default();
        c.set_owner("1");
        c.merge("contacts", "", "a".into(), json!([1]));
        c.set_owner("2");
        assert!(c.entries.is_empty());
    }
}

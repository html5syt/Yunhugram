//! 按职责组织云湖客户端 Protobuf 协议。
mod account;
mod lists;
mod websocket;
pub use account::*;
pub use lists::*;
pub use websocket::*;
#[cfg(test)]
mod tests {
    use super::*;
    use prost::Message;
    #[test]
    fn cache_hash_uses_field_two_not_one() {
        let encoded = ListRequest { md5: "abc".into() }.encode_to_vec();
        assert_eq!(encoded, vec![0x12, 3, b'a', b'b', b'c']);
    }
    #[test]
    fn contact_group_preserves_type_and_remark() {
        let group = ContactGroup {
            chat_type: 2,
            list_name: "群聊".into(),
            data: vec![Contact {
                chat_id: "12".into(),
                remark: "备注".into(),
                ..Default::default()
            }],
        };
        let decoded = ContactGroup::decode(group.encode_to_vec().as_slice()).unwrap();
        assert_eq!(decoded.chat_type, 2);
        assert_eq!(decoded.data[0].remark, "备注");
    }
}

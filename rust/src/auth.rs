//! 登录与注册请求，只使用已核实的客户端字段。
use serde_json::{Value, json};

/// 按客户端命令生成请求；不把界面额外状态发送给后端。
pub fn request(
    kind: &str,
    args: &Value,
    device: &str,
    platform: &str,
) -> Option<(&'static str, Value)> {
    let mobile = args["mobile"].as_str().unwrap_or_default();
    let captcha = args["captcha"].as_str().unwrap_or_default();
    Some(match kind {
        "emailLogin" => (
            "v1/user/email-login",
            json!({"email":args["email"], "password":args["password"], "deviceId":device, "platform":platform}),
        ),
        "phoneLogin" => (
            "v1/user/verification-login",
            json!({"mobile":mobile,"captcha":captcha,"deviceId":device,"platform":platform}),
        ),
        "registerPhone" => (
            "v1/user/verification-register",
            json!({"mobile":mobile,"captcha":captcha,"deviceId":device,"platform":platform,"nickname":args["nickname"],"inviteCode":args["inviteCode"].as_str().unwrap_or_default()}),
        ),
        "sendCode" => {
            let mut body = json!({"mobile":mobile,"id":args["id"],"platform":platform});
            if args["captchaType"] == "slide" {
                body["captcha_type"] = json!("slide");
                body["x"] = args["x"].clone();
            } else {
                body["code"] = args["code"].clone();
            }
            ("v1/verification/get-verification-code", body)
        }
        _ => return None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn registration_matches_verified_object_pool() {
        let (path, body) = request("registerPhone", &json!({"mobile":"13800138000","captcha":"123456","nickname":"测试","inviteCode":"abc","password":"never-send"}), "device", "windows").unwrap();
        assert_eq!(path, "v1/user/verification-register");
        assert_eq!(
            body,
            json!({"mobile":"13800138000","captcha":"123456","nickname":"测试","inviteCode":"abc","deviceId":"device","platform":"windows"})
        );
    }
    #[test]
    fn slide_coordinates_are_not_display_coordinates() {
        let (_, body) = request(
            "sendCode",
            &json!({"mobile":"13800138000","id":"challenge","captchaType":"slide","x":132}),
            "device",
            "android",
        )
        .unwrap();
        assert_eq!(body["x"], 132);
        assert_eq!(body["captcha_type"], "slide");
        assert!(body.get("code").is_none());
    }
    #[test]
    fn image_challenge_uses_code_without_slide_fields() {
        let (_, body) = request(
            "sendCode",
            &json!({"mobile":"13800138000","id":"challenge","code":"Ab12"}),
            "device",
            "windows",
        )
        .unwrap();
        assert_eq!(body["code"], "Ab12");
        assert!(body.get("captcha_type").is_none());
        assert!(body.get("x").is_none());
    }
}

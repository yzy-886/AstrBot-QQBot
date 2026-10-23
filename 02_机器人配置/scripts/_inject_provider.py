import json, sys

CFG = "/AstrBot/data/cmd_config.json"
key = open("/tmp/deepseek.key", encoding="utf-8").read().strip()

with open(CFG, encoding="utf-8-sig") as f:
    cfg = json.load(f)

entry = {
    "id": "deepseek",
    "provider": "deepseek",
    "type": "openai_chat_completion",
    "provider_type": "chat_completion",
    "enable": True,
    "key": [key],
    "api_base": "https://api.deepseek.com/v1",
    "timeout": 120,
    "proxy": "",
    "custom_headers": {},
    "model_config": {"model": "deepseek-flash"},
    "model": "deepseek-flash",
    # 关闭思考模式：否则每句话先想十几秒，且思考 token 按输出价计费
    "custom_extra_body": {"thinking": {"type": "disabled"}},
}

cfg["provider"] = [entry]
cfg.setdefault("provider_settings", {})["enable"] = True
cfg["provider_settings"]["provider_pool"] = ["*"]

with open(CFG, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)

print("provider written:", cfg["provider"][0]["id"], "model:", cfg["provider"][0]["model"])
print("key prefix:", key[:6] + "***")

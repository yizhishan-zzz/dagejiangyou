# 打个酱油

面向近距离社区生活的任务协作与拼单应用，提供发布需求、接单履约、社区拼单、账户设置和双角色工作台。

## 构建

默认接口地址为 http://127.0.0.1:8080/api/v1。部署到服务器时通过编译参数注入：

    flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api/v1

生产 APK 需要配置 Android release keystore。复制 `android/key.properties.example` 为 `android/key.properties`，填写真实密钥信息后再构建；没有密钥时仍会回退到 debug 签名，仅适用于内部安装验证。

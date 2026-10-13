# Contributing

感谢你对 Mouse Drag 的兴趣！提交贡献前请注意：

1. **代码风格**：遵循项目现有的 Lua 风格（4 空格缩进、中文注释习惯保留）。
2. **兼容性**：改动必须同时兼容原版 / 巨人国 / 船难 / 猪镇；不要引入联机版（DST）专属 API。
3. **测试**：至少在单机版中实际进游戏验证一遍再提交 PR。
4. **Issue**：报告 bug 时请附上游玩的游戏版本（RoG / SW / HAM）、模组配置与复现步骤。

## 发布流程（维护者）

- 修改 `modinfo.lua` 中的 `version` 字段。
- 将 `images/` 与 `anim/` 下的美术资源一并打包（`.tex/.xml/.zip` 为二进制，不入 git，见 README 说明）。
- 打 tag（如 `v4.1.0`）并在 GitHub 创建 Release，附上游戏内适用的 zip 包。

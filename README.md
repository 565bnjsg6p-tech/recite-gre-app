# Recite GRE

一个面向 GRE / IELTS / TOEFL 备考的个人背单词应用。当前阶段优先完成 Web 版本，技术上采用 Flutter，后续可以继续扩展到 iOS、macOS、Windows 和 Android。

项目的核心目标是：录入单词要快，补全资料要省 token，复习要有节奏，数据要能多端同步。

## 当前状态

已经完成的主要能力：

- 英语 / 德语入口选择，德语模块暂时留空。
- 邮箱注册、登录、退出登录，基于 Supabase Auth。
- 本地优先词库，基于 Drift + SQLite / Web IndexedDB。
- Supabase 云同步，已验证词卡和复习记录可以推送、拉取。
- 批量录入英文单词。
- 内置考试词典补全，包含 GRE / IELTS / TOEFL 相关词条。
- AI 补全队列，用户可在设置页保存 OpenAI API Key 后批量补全。
- 词典补全、AI 补全、待补全等状态标记。
- 词库页筛选、查看详情、编辑内容、删除、批量操作。
- Anki 风格复习卡片。
- 简化 SM-2 间隔重复算法。
- 学习计划页：每日新词、每日复习上限、考试日期、学习曲线。
- Web 本地 JSON 导出 / 导入 / 清空数据。
- 旧本地数据库结构自动修复，避免升级后缺字段导致页面空白。

## 产品链路

用户第一次打开网站：

1. 进入语言选择页。
2. 点击英语。
3. 进入登录 / 注册页。
4. 新用户注册邮箱和密码，老用户直接登录。
5. 登录成功后进入主应用。

日常学习链路：

1. 在“录入”页批量粘贴单词。
2. 选择补全方式：
   - 基础词典：优先使用内置词典，零 token，适合大量快速入库。
   - AI 队列：先标记为待 AI 补全，后续统一调用 OpenAI。
   - 只入库：只保存单词，之后再决定怎么补全。
3. 在“词库”页查看、筛选、编辑、删除单词。
4. 在“复习”页按 Anki 卡片复习，选择“不认识 / 犹豫 / 认识”。
5. 系统按简化 SM-2 算法更新下次复习时间。
6. 在“计划”页查看长期添加单词和复习曲线。
7. 在“设置”页手动同步或等待登录后自动同步。

多端同步链路：

1. 本地数据先写入 Drift 数据库，页面立即可用。
2. 每条词卡、复习记录、学习计划都有本地更新时间和同步状态。
3. 同步时先 push 本地 dirty 数据到 Supabase。
4. 再 pull 云端数据回本地。
5. 冲突策略暂时采用“更新时间较新的版本优先”。
6. 换浏览器或换设备登录同一账号后，可以从云端拉回词库和复习记录。

## 技术栈

- Flutter：跨平台 UI 框架，目前主攻 Web。
- Drift：本地数据库 ORM。
- SQLite / IndexedDB：本地持久化，Web 端通过 sqlite3 wasm + worker。
- Supabase Auth：用户注册和登录。
- Supabase Postgres：云端词库、复习记录、学习计划同步。
- SharedPreferences：保存 API Key、学习计划、本地配置等轻量设置。
- OpenAI API：生成中文释义、GRE 考点、词根词缀、例句、记忆提示。
- ECDICT：内置考试词典来源。

## 目录结构

```text
lib/
  main.dart                         应用入口，初始化 Supabase
  recite_app.dart                   顶层应用、语言选择、登录状态流转
  src/config/supabase_config.dart   Supabase URL 和 anon key
  src/data/
    app_database.dart               Drift 表结构、迁移、旧库修复、查询方法
    app_store.dart                  业务状态中心，连接 UI、数据库、词典、AI、复习
    app_preferences.dart            本地轻量设置
    auth_repository.dart            Supabase 登录注册，本地测试登录实现
    sync_service.dart               Supabase 云同步逻辑
    openai_word_enricher.dart       OpenAI 单词补全
    mock_repository.dart            初始示例词
    word_entry.dart                 UI 层使用的数据模型
  src/ui/
    app_shell.dart                  主界面导航
    pages/                          今日、复习、录入、词库、计划、设置等页面
    widgets/                        通用页面布局和卡片组件
  src/theme/app_theme.dart          主题颜色和控件样式

assets/dictionaries/
  exam_basic.json                   内置考试词典
  exam_basic_meta.json              词典元信息
  ECDICT_LICENSE.txt                ECDICT 授权说明

docs/
  setup.md                          本地环境说明
  dictionary.md                     词典构建说明
  supabase_schema.sql               Supabase 表结构和 RLS policy

tool/
  build_dictionary.js               从 ECDICT CSV 生成内置词典
  ecdict.csv                        词典源数据
  verify_supabase_sync_app.dart     真实 Supabase 同步验证入口
```

## 本地运行

先确认 Flutter 可用：

```powershell
flutter doctor
flutter pub get
```

启动 Web 开发服务：

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173
```

浏览器访问：

```text
http://localhost:5173/
```

如果本机 Flutter 不在 PATH，可以临时加上：

```powershell
$env:Path='D:\c\flutter\bin;' + $env:Path
```

## Supabase 配置

1. 创建 Supabase 项目。
2. 在 Supabase SQL Editor 中运行：

```text
docs/supabase_schema.sql
```

3. 将项目 URL 和 anon key 写入：

```text
lib/src/config/supabase_config.dart
```

当前云端表：

- `profiles`：用户资料。
- `word_cards`：词卡内容、AI 资料、复习状态。
- `review_logs`：每次复习记录。
- `study_settings`：每日新词、每日复习上限、考试日期等设置。

所有表都启用了 Row Level Security，只允许用户访问自己的数据。

## 数据模型

本地核心表在 `app_database.dart`：

### word_cards

保存单词卡片：

- `id`：本地 ID。
- `user_id`：所属用户。
- `remote_id`：Supabase 远端 ID。
- `sync_status`：`dirty` / `synced` / `deleted`。
- `word`：英文单词。
- `chinese_meaning`：中文释义。
- `english_meaning`：英文释义。
- `gre_focus`：GRE 考点。
- `roots_json`：词根词缀 JSON。
- `synonyms_json`：同义词 JSON。
- `antonyms_json`：反义词 JSON。
- `example`：例句。
- `memory_tip`：记忆提示。
- `note`：用户备注。
- `tags_json`：标签 JSON。
- `mastery`：掌握程度。
- `due_at`：下次复习时间。
- `review_count`：复习次数。
- `lapse_count`：忘记次数。
- `ease_factor`：SM-2 难度系数，默认 250。
- `interval_days`：当前复习间隔。
- `enrichment_status`：补全状态。
- `created_at` / `updated_at` / `deleted_at`：时间戳。

### review_logs

保存每次复习：

- `id`：本地自增 ID。
- `user_id`：所属用户。
- `remote_id`：Supabase 远端 ID。
- `word_id`：本地词卡 ID。
- `rating`：`forgot` / `shaky` / `known`。
- `reviewed_at`：复习时间。
- `sync_status`：同步状态。

## 补全状态

当前使用的补全状态：

- `queued`：只入库，等待后续补全。
- `dictionary`：由内置词典补全。
- `queued_ai`：等待 AI 补全。
- `ai`：已由 AI 补全。
- `failed`：AI 补全失败，可重新加入队列。

词典补全适合大批量录入，AI 补全适合重点词深度加工。

## 内置词典

词典来源是 ECDICT：

- 源项目：https://github.com/skywind3000/ECDICT
- 生成文件：`assets/dictionaries/exam_basic.json`
- 授权文件：`assets/dictionaries/ECDICT_LICENSE.txt`

重新生成词典：

```powershell
node tool\build_dictionary.js
```

生成逻辑：

- 保留带 `gre`、`ielts`、`toefl` 标签的词。
- 去掉一小批过于基础的词。
- 输出字段保持简单，方便以后换词典源。

## AI 补全

目前是自用简易版：

1. 进入设置页。
2. 输入 OpenAI API Key。
3. 输入模型名，默认 `gpt-5-mini`。
4. 点击一键 AI 补全。

注意：

- API Key 只存在当前浏览器本地。
- 这个方案适合自用测试，不适合公开部署。
- 正式部署建议改为后端代理，例如 Supabase Edge Function 或 Cloudflare Worker。

AI 输出会尽量生成结构化数据：

- 中文释义
- 英文释义
- GRE 考点
- 词根词缀
- 同义词
- 反义词
- 例句
- 记忆提示
- 标签

## 复习算法

当前是简化 SM-2：

- 不认识：间隔重置为 0 天，当天继续出现，ease factor 降低。
- 犹豫：短间隔复习，ease factor 小幅变化。
- 认识：按 1 天、6 天、之后乘以 ease factor 的方式增长。

掌握等级：

- `newWord`
- `learning`
- `familiar`
- `mastered`

下一步可以继续优化：

- 加入当天再次出现的队列权重。
- 统计连续答对次数。
- 区分拼写、释义、例句理解等不同题型。

## 同步机制

同步入口在 `sync_service.dart`。

当前流程：

1. 检查用户是否已经登录 Supabase。
2. 查询本地 `dirty` 或 `deleted` 数据。
3. 上传 `word_cards`。
4. 上传 `review_logs`。
5. 同步 `study_settings`。
6. 拉取云端 `word_cards`。
7. 拉取云端 `review_logs`。
8. 更新本地 `remote_id` 和 `sync_status`。

已做真实验证：

```text
SYNC_VERIFICATION_OK
pushed=2, pulled=2
```

验证入口：

```text
tool/verify_supabase_sync_app.dart
```

这个验证会创建临时测试账号，写入一张词卡和一条复习记录，推送到 Supabase，再用新的本地 Web 数据库拉回来。

## 常用开发命令

获取依赖：

```powershell
flutter pub get
```

代码检查：

```powershell
flutter analyze
```

运行测试：

```powershell
flutter test
```

构建 Web：

```powershell
flutter build web
```

启动 Web：

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173
```

生成 Drift 代码：

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## 当前验证结果

最近一次完整验证：

- `flutter analyze`：通过。
- `flutter test`：6 个测试通过。
- `flutter build web`：通过。
- Supabase 真实同步验证：通过，`word_cards` 和 `review_logs` 可 push / pull。

## 已知注意点

- Windows 桌面运行如果提示 symlink，需要在系统设置中开启 Developer Mode。
- 当前公开部署前不建议把 OpenAI API Key 放在前端。
- Supabase anon key 可以放前端，但 service role key 绝对不能放前端。
- Web 浏览器可能缓存旧 Flutter 脚本，`web/index.html` 已加入清理旧 service worker 和 cache 的逻辑。
- 本地数据库升级时要维护迁移逻辑，避免老用户 IndexedDB 表结构缺字段。
- 当前德语入口只是占位，尚未建立德语词库、复习模型和 UI 文案。

## 后续路线

优先级建议：

1. 完善同步体验：同步进度、失败重试、首次登录迁移提示。
2. 做正式后端 AI 代理：隐藏 API Key，控制 token 用量。
3. 增强复习体验：复习结束页、每日统计、错词优先、卡片动画。
4. 增强词库管理：更强搜索、标签管理、批量编辑、导入 CSV。
5. 部署 Web 版本：绑定域名、开启 HTTPS、配置 Supabase Auth redirect URL。
6. 打包桌面版本：Windows、macOS。
7. 打包移动版本：iOS 优先，Android 后续。
8. 启动德语模块：德语词库、词性、例句和复习提示单独建模。

## 部署平台建议

这三个平台都能部署 Flutter Web 静态站点，差别主要在预览、域名和团队协作体验。

| 平台 | 优点 | 缺点 | 适合场景 |
| --- | --- | --- | --- |
| Cloudflare Pages | 静态站点很合适，支持自定义域名、重定向、回滚，整体偏轻。 | 动态后端能力不是主打，复杂应用要额外接 Workers。 | 当前这个 Flutter Web 学习站，最省心。 |
| Netlify | Deploy Preview 和团队预览体验很好，路由、重定向、头部配置也顺手。 | 站点多了以后配置项会更分散，域名体系偏 Netlify 风格。 | 你要经常让朋友看预览、一起改页面时。 |
| Vercel | 前端项目和预览部署体验很成熟，域名和重定向配置也完善。 | 对纯 Flutter 静态站来说有点“重”，强项更偏现代前端框架。 | 如果后面要接复杂前端路由或 Next.js 一类项目。 |

### 我的推荐

**优先选 Cloudflare Pages。**

原因很简单：

- 你现在的主站是 Flutter Web 静态产物，Cloudflare Pages 很对口。
- 后面如果要绑正式域名、做重定向、做回滚，Cloudflare Pages 都能覆盖。
- 这个项目当前还没到特别重的前端框架阶段，先用最轻的一层就够了。

参考文档：

- Cloudflare Pages: https://developers.cloudflare.com/pages/
- Netlify Deploy Previews: https://docs.netlify.com/site-deploys/deploy-previews/
- Vercel Deployments: https://vercel.com/docs/deployments/overview

## 部署步骤

下面按 Cloudflare Pages 写，最适合现在这个项目。

1. 把项目推到 GitHub。
2. 登录 Cloudflare Dashboard，创建 Pages 项目。
3. 连接 GitHub 仓库。
4. 构建命令填：

```text
flutter build web
```

5. 输出目录填：

```text
build/web
```

6. 首次部署后，拿到一个临时预览地址。
7. 在 Supabase 后台把这个正式域名加入：
   - Site URL
   - Redirect URLs
8. 确认登录、注册、同步、录入、复习都正常。
9. 如果以后你要换正式域名，再把新域名补进 Supabase 和 Cloudflare。

### 部署后要检查的点

- 刷新页面不会空白。
- 登录后会自动进入主应用。
- 录入的单词能在当前浏览器保留。
- 同一个账号在第二个浏览器里能拉回数据。
- 计划页和设置页都能正常读取本地设置。

## 试用检查清单

这是你发给朋友试用时，最值得逐项确认的流程：

1. 打开网站后能先选英语。
2. 新用户可以注册。
3. 老用户可以直接登录。
4. 登录后能看到今日页和同步状态。
5. 批量录入单词没问题。
6. 基础词典补全能命中一批词。
7. AI 队列能正常标记。
8. 复习卡片能翻面和评分。
9. 复习后下次到期时间会变化。
10. 计划页能改每日新词、每日复习上限、考试日期。
11. 设置页能看到同步状态和最后同步时间。
12. 导出 JSON / 导入 JSON 能正常工作。
13. 同一个账号换浏览器后能拉回词库。
14. 旧本地词库绑定账号时会先弹确认，不会悄悄合并。

## 协作建议

如果朋友要一起研究，建议从这几个文件开始读：

1. `lib/recite_app.dart`：了解整个 App 的入口流转。
2. `lib/src/data/app_store.dart`：了解业务逻辑。
3. `lib/src/data/app_database.dart`：了解本地数据结构。
4. `lib/src/data/sync_service.dart`：了解云同步。
5. `lib/src/ui/pages/word_input_page.dart`：了解批量录入。
6. `lib/src/ui/pages/review_page.dart`：了解复习流程。
7. `docs/supabase_schema.sql`：了解云端表结构。

推荐分工：

- 一个人负责 UI 和交互。
- 一个人负责同步、数据库和部署。
- 一个人负责词典、AI prompt、复习算法。

这个项目最重要的设计原则是“本地优先”。用户录入和复习不能被网络卡住；云同步只是让数据跨浏览器、跨设备继续流动。

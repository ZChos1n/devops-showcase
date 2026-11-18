# 把项目推到 GitHub（3 分钟搞定）

WorkBuddy 的 GitHub 连接器只有**读权限**，无法创建仓库或写入文件（会报 `403 Resource not accessible by integration`）。所以用你自己的 GitHub 凭证在本地推送——这是标准做法，也更安全。

---

## 第 1 步：生成一个 Personal Access Token（PAT）

1. 打开 https://github.com/settings/tokens/new
2. 按如下填写：
   - **Note**：`devops-showcase-push`
   - **Expiration**：建议 `90 days`
   - **Select scopes**：只勾选 **`repo`**（这一项就够了，包含读写仓库）
3. 点底部 **Generate token**
4. **立即复制**那串 `ghp_` 开头的字符（页面刷新后再也看不到）

> 只需要 `repo` 权限，不要勾选 delete_repo、admin 等其它 scope。

---

## 第 2 步：运行推送脚本

在项目目录打开终端（PowerShell 或 Git Bash），执行：

**Git Bash / macOS / Linux：**
```bash
cd 项目目录/devops-showcase
GH_TOKEN="你的ghp_token" bash scripts/push.sh
```

**Windows PowerShell：**
```powershell
cd 项目目录\devops-showcase
$env:GH_TOKEN="你的ghp_token"
bash scripts/push.sh
```

脚本会自动完成：配置 remote → 分支改 main → 推送 → 清理凭证（token 不会写进任何配置文件）。

---

## 第 3 步：验证

打开 https://github.com/ZChos1n/devops-showcase ，应看到 53 个文件、README 正确渲染。

---

## 常见问题

- **报 `Authentication failed`**：token 复制时多了空格，或没勾 `repo` scope，重新生成。
- **报 `repository not found`**：确认空仓库已建好且名为 `devops-showcase`。
- **想更省心**：安装 [GitHub CLI](https://cli.github.com/) 后运行 `gh auth login`， subsequent push 无需 token。
- **推送后想删 token**：用完可在 https://github.com/settings/tokens 撤销，随用随建最安全。

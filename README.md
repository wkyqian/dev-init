# dev-init

一行命令由三段拼出来：

```
TOKEN="..." KEY="..." <按系统和网络选下面一行>
```

- `TOKEN="..."`：把 `...` 换成你的密钥。
- `KEY="..."`：有多加的公钥就把 `...` 换掉，没有就留着 `...`，等于没有。
- Windows 在管理员 PowerShell 里跑；Linux / macOS 直接在终端跑。

## 直连

Windows：

```powershell
$env:TOKEN="..."; $env:KEY="..."; irm https://raw.githubusercontent.com/wkyqian/dev-init/main/init.ps1 | iex
```

Linux：

```bash
TOKEN="..." KEY="..." bash -c "$(curl -fsSL https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

macOS：

```bash
TOKEN="..." KEY="..." bash -c "$(curl -fsSL https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

## 国内加速

Windows：

```powershell
$env:TOKEN="..."; $env:KEY="..."; irm https://ghfast.top/https://raw.githubusercontent.com/wkyqian/dev-init/main/init.ps1 | iex
```

Linux：

```bash
TOKEN="..." KEY="..." bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

macOS：

```bash
TOKEN="..." KEY="..." bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

# dev-init

一行命令由三段拼出来：

```
TOKEN="..." [KEY="..."] <按系统和网络选下面一行>
```

- `TOKEN="..."`：必填。把 `...` 换成你的密钥。
- `KEY="..."`：可选。想多加一把公钥时才加，不加只写默认那把。
- Windows 在管理员 PowerShell 里跑；Linux / macOS 直接在终端跑。

## 直连

Windows：

```powershell
$env:TOKEN="..."; irm https://raw.githubusercontent.com/wkyqian/dev-init/main/init.ps1 | iex
```

Linux：

```bash
TOKEN="..." bash -c "$(curl -fsSL https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

macOS：

```bash
TOKEN="..." bash -c "$(curl -fsSL https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

## 国内加速

Windows：

```powershell
$env:TOKEN="..."; irm https://ghfast.top/https://raw.githubusercontent.com/wkyqian/dev-init/main/init.ps1 | iex
```

Linux：

```bash
TOKEN="..." bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

macOS：

```bash
TOKEN="..." bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

## 带 KEY 的例子

Linux 直连，加 `KEY` 时把它放在 `TOKEN` 后面，Windows 同理加 `$env:KEY="...";`：

```bash
TOKEN="..." KEY="..." bash -c "$(curl -fsSL https://raw.githubusercontent.com/wkyqian/dev-init/main/init.sh)"
```

# portable-ocr

Windows、macOS 和 Linux 命令行 OCR 工具。使用 SimdPaddleOCR 和 PP-OCRv6 Medium 在 CPU 上离线识别 PNG 截图中的文字，并返回原图像素坐标。

## 下载与运行

从 [Releases](https://github.com/one-click-run/portable-ocr/releases) 下载适合系统与处理器的压缩包并解压。可执行文件已包含模型和所需的 .NET 运行时代码，无需安装 Python、.NET 或 OCR 语言包，也无需联网下载模型。

| 系统 | 下载文件 | 支持范围 |
| --- | --- | --- |
| Windows | `portable-ocr-win-x64.zip` | x64；Windows 10 / 11 |
| macOS，Intel 芯片 | `portable-ocr-osx-x64.tar.gz` | macOS 15 或更新版本 |
| macOS，Apple 芯片 | `portable-ocr-osx-arm64.tar.gz` | macOS 15 或更新版本 |
| Linux，Intel / AMD | `portable-ocr-linux-x64.tar.gz` | glibc 2.35 或更新版本，例如 Ubuntu 22.04 / 24.04 |
| Linux，ARM64 | `portable-ocr-linux-arm64.tar.gz` | glibc 2.35 或更新版本，例如 Ubuntu 22.04 / 24.04 ARM64 |

Windows：

```powershell
.\portable-ocr.exe .\screenshot.png
```

macOS / Linux（以下以 Apple 芯片 Mac 为例，其他平台替换压缩包名）：

```sh
tar -xzf portable-ocr-osx-arm64.tar.gz
cd portable-ocr-osx-arm64
./portable-ocr /path/to/screenshot.png
```

运行只需包内的 `portable-ocr.exe` 或 `portable-ocr` 文件。macOS / Linux 压缩包保留执行权限；若复制文件后权限丢失，可执行 `chmod +x ./portable-ocr`。输入路径包含空格时加引号。使用 `--help` 查看命令用法。

macOS 版本未使用 Apple Developer ID 签名和公证。下载后可能被 Gatekeeper 拦截，需要在“系统设置 → 隐私与安全性”中允许打开。Linux 使用系统自带的 glibc 等基础库，不依赖 ICU；Alpine（musl）不在这些下载包的支持范围内。

每个压缩包附带 `.sha256` 校验文件。macOS 使用 `shasum -a 256 -c <压缩包名>.sha256`，Linux 使用 `sha256sum -c <压缩包名>.sha256`，Windows 使用 `Get-FileHash <压缩包名> -Algorithm SHA256` 与校验文件比较。

## 输出

成功时，标准输出为一行 UTF-8 JSON。宽高和坐标以输入图片的像素为单位，原点在左上角。每行包含文字、原始识别分数和四个角的坐标。`recognitionScore` 保留推理库的返回值，取值可以大于 1。

```json
{
  "width": 800,
  "height": 600,
  "lines": [
    {
      "text": "开始测试",
      "recognitionScore": 19.7,
      "topLeft": {"x": 40, "y": 80},
      "topRight": {"x": 160, "y": 80},
      "bottomRight": {"x": 160, "y": 120},
      "bottomLeft": {"x": 40, "y": 120}
    }
  ]
}
```

未识别到文字时，`lines` 为空数组。退出码 `0` 表示成功，`1` 表示读取或识别失败，`2` 表示参数错误。错误写入标准错误。

## 构建

安装 `global.json` 指定的 .NET SDK 10.0.404 和 PowerShell 7.4 或更新版本。Native AOT 需要在目标操作系统及处理器架构上打包：

- Windows：Visual Studio 2022 或 Build Tools 的 C++ 桌面开发组件和 Windows SDK。
- macOS：Xcode Command Line Tools（`xcode-select --install`）。
- Ubuntu：`sudo apt-get install clang zlib1g-dev`。

在仓库根目录运行以下命令，`-Runtime` 可选 `win-x64`、`osx-x64`、`osx-arm64`、`linux-x64` 或 `linux-arm64`：

```powershell
pwsh -File ./scripts/package.ps1 -Runtime win-x64
```

压缩包与 SHA-256 校验文件位于 `dist/`，包内含可执行文件、使用说明和第三方许可，调试符号不会进入压缩包。再次打包同一平台前，请移走或删除对应的 `dist/portable-ocr-<Runtime>/` 目录及已有压缩包。依赖还原使用 `--locked-mode`，修改依赖或运行目标后需先运行 `dotnet restore` 更新 `packages.lock.json`。

默认使用通用 CPU 指令集，优先兼容不同处理器；没有强制要求 AVX2。项目启用 invariant globalization，中文识别与 UTF-8 JSON 输出保持原有契约。

## GitHub Actions

版本号统一维护在 `portable-ocr.csproj` 的 `<Version>` 中，格式为 `主版本.次版本.修订号`，例如 `0.1.1`。更新该版本号并提交推送到 `main` 即可发布，无需手动创建标签、Release 或触发工作流。

每次推送到 `main`，工作流先检查对应的 `v<Version>` Release 是否已存在（包括草稿）。已存在时跳过编译和发布；不存在时才构建五个平台，全部成功后自动在该次提交上创建版本标签并公开发布 Release，附上五个平台压缩包、SHA-256 校验文件和自动生成的版本说明。若同名标签已经指向其他提交，工作流会报错，需使用新版本号。

构建失败时不会发布 Release，可修正代码后重新推送相同版本号，或在 [Actions](https://github.com/one-click-run/portable-ocr/actions) 中重新运行失败任务。工作流使用内置 `GITHUB_TOKEN`，无需额外配置发布 Secret；仓库或组织需允许 Actions，并允许该工作流创建 Release。已发布版本的附件保持原样，后续修改需更新版本号。

macOS 包当前只带 Native AOT 的本地签名，没有 Developer ID 签名、公证或相关 Secret；完整的 Apple 分发签名需另行配置证书。

第三方来源和许可见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

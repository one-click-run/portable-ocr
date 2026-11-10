# android-ocr

Windows x64 命令行工具。使用 SimdPaddleOCR 和 PP-OCRv6 Medium 在 CPU 上离线识别截图中的文字，并返回原图像素坐标。

```powershell
.\android-ocr.exe .\screenshot.png
```

运行只需 `android-ocr.exe`。模型已内嵌，测试机无需安装 Python、.NET 或额外的 OCR 语言包。

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

在 Windows x64 上安装 .NET SDK 10.0.404、Visual Studio 2022 或 Build Tools 的 C++ 桌面开发组件和 Windows SDK。还原 NuGet 依赖后使用 Native AOT 构建。

```powershell
dotnet restore --locked-mode
dotnet publish -c Release --no-restore -o dist
```

产物位于 `dist/android-ocr.exe`。第三方来源和许可见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

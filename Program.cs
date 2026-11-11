using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Sdcb.SimdCodecs.Png;
using Sdcb.SimdPaddleOCR;
using Sdcb.SimdPaddleOCR.Models.ChineseV6Medium;

Console.OutputEncoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: false);

if (args is ["-h" or "--help"])
{
    Console.WriteLine("Usage: portable-ocr <image.png>");
    return 0;
}

if (args is not [var imagePath] || imagePath.StartsWith('-'))
{
    Console.Error.WriteLine("Usage: portable-ocr <image.png>");
    return 2;
}

try
{
    if (!PngImageDecoder.TryDecodeRgba8(File.ReadAllBytes(imagePath), out var pixels, out var width, out var height))
    {
        throw new InvalidDataException("Could not decode the PNG image.");
    }
    using var engine = PaddleOcrAll.Load(ChineseV6MediumModels.Default, new PaddleOcrOptions
    {
        Detector = new() { Backend = OcrBackend.Cpu },
        Classifier = new() { Backend = OcrBackend.Cpu },
        Recognizer = new() { Backend = OcrBackend.Cpu },
    });
    var result = engine.Run(pixels, width, height, format: ImagePixelFormat.Rgba32);
    var lines = result.Lines.Select(line => new OcrLine(
        line.Text,
        line.RecognitionScore,
        new Point(line.Box.X1, line.Box.Y1),
        new Point(line.Box.X2, line.Box.Y2),
        new Point(line.Box.X3, line.Box.Y3),
        new Point(line.Box.X4, line.Box.Y4)
    )).ToArray();

    Console.WriteLine(JsonSerializer.Serialize(
        new OcrResponse(width, height, lines),
        OcrJsonContext.Default.OcrResponse));
    return 0;
}
catch (Exception error)
{
    Console.Error.WriteLine($"portable-ocr: {error.Message}");
    return 1;
}

internal sealed record OcrResponse(int Width, int Height, OcrLine[] Lines);
internal sealed record OcrLine(string Text, float RecognitionScore, Point TopLeft, Point TopRight, Point BottomRight, Point BottomLeft);
internal readonly record struct Point(float X, float Y);

[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(OcrResponse))]
internal sealed partial class OcrJsonContext : JsonSerializerContext;

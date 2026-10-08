using TacticalGo.Domain;

namespace TacticalGo.Play;

/// <summary>Six unmodified VIS-FEEL-01 candidates embedded in the executable; images are shared only on their UI thread.</summary>
internal static class HeroArt
{
    [ThreadStatic] private static Dictionary<HeroClass, Image>? _tokens;
    [ThreadStatic] private static Dictionary<HeroClass, Image>? _portraits;

    public static Image? Token(HeroClass hero) => (_tokens ??= LoadSet("A", 512)).GetValueOrDefault(hero);
    public static Image? Portrait(HeroClass hero) => (_portraits ??= LoadSet("B", 112)).GetValueOrDefault(hero);

    private static Dictionary<HeroClass, Image> LoadSet(string variant, int size)
    {
        var images = new Dictionary<HeroClass, Image>();
        foreach (var (hero, name, version) in new[] {
            (HeroClass.Warrior, "warrior", variant == "A" ? "v01" : "v02"),
            (HeroClass.Mage, "mage", variant == "A" ? "v01" : "v02"),
            (HeroClass.Rogue, "rogue", "v02") })
        {
            using var stream = typeof(HeroArt).Assembly.GetManifestResourceStream($"TacticalGo.Play.HeroArt.{variant}-{name}-{version}.png")
                ?? throw new InvalidOperationException($"Missing embedded hero candidate: {variant}-{name}");
            using var source = Image.FromStream(stream);
            var image = new Bitmap(size, size);
            using (var graphics = Graphics.FromImage(image))
            {
                graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                graphics.DrawImage(source, new Rectangle(0, 0, size, size));
            }
            images.Add(hero, image);
        }
        return images;
    }
}

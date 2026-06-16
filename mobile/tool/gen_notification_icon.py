from PIL import Image, ImageDraw
import os

base = os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "res")
sizes = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}
for folder, size in sizes.items():
    path = os.path.join(base, folder)
    os.makedirs(path, exist_ok=True)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size
    white = (255, 255, 255, 255)
    d.ellipse((s * 0.22, s * 0.18, s * 0.78, s * 0.72), fill=white)
    d.rectangle((s * 0.44, s * 0.10, s * 0.56, s * 0.22), fill=white)
    d.rectangle((s * 0.18, s * 0.68, s * 0.82, s * 0.78), fill=white)
    d.ellipse((s * 0.42, s * 0.78, s * 0.58, s * 0.92), fill=white)
    img.save(os.path.join(path, "ic_notification.png"))
print("generated ic_notification.png for all densities")


import torch
from PIL import Image, ImageDraw
from diffusers import StableDiffusionInpaintPipeline

MODEL_ID = "stable-diffusion-v1-5/stable-diffusion-inpainting"

print("Loading model...")
pipe = StableDiffusionInpaintPipeline.from_pretrained(
    MODEL_ID,
    torch_dtype=torch.float32,
    safety_checker=None,
)
pipe.to("cpu")
pipe.enable_attention_slicing()

# Create a simple test room image
image = Image.new("RGB", (256, 256), (220, 220, 220))
draw = ImageDraw.Draw(image)
draw.rectangle((0, 0, 255, 150), fill=(235, 230, 215))
draw.rectangle((0, 150, 255, 255), fill=(160, 130, 100))

# White mask means the area can be redesigned
mask = Image.new("L", (256, 256), 255)

prompt = (
    "A photorealistic modern living room, elegant beige sofa, "
    "wooden coffee table, indoor plants, warm natural lighting, "
    "professional interior design photography"
)

print("Generating redesigned room...")
with torch.inference_mode():
    result = pipe(
        prompt=prompt,
        image=image,
        mask_image=mask,
        num_inference_steps=5,
        guidance_scale=5.0,
        strength=1.0,
    ).images[0]

result.save("redesign_test.png")
print("SUCCESS: Image saved as redesign_test.png")

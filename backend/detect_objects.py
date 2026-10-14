
import os
import json
import cv2
import torch
import numpy as np

from PIL import Image
from ultralytics import YOLO
from sam2.build_sam import build_sam2
from sam2.sam2_image_predictor import SAM2ImagePredictor


# ----------------------------------------
# CONFIGURATION
# ----------------------------------------

IMAGE_PATH = r"C:\Users\asus\Downloads\room.jpg"

YOLO_MODEL = "yolo26n-seg.pt"
SAM_CHECKPOINT = "checkpoints/sam2.1_hiera_base_plus.pt"
SAM_CONFIG = "configs/sam2.1/sam2.1_hiera_b+.yaml"

OUTPUT_DIR = "detected_objects"

os.makedirs(OUTPUT_DIR, exist_ok=True)

original = Image.open(IMAGE_PATH).convert("RGB")
image = np.array(original)

H, W = image.shape[:2]
saved_count = 0


import numpy as np

def is_duplicate_mask(new_mask, existing_masks, threshold=0.70):
    """
    Returns True if the new mask overlaps an existing mask
    enough to be considered the same object.
    """
    new_mask = np.asarray(new_mask).astype(bool)

    for existing_mask in existing_masks:
        existing_mask = np.asarray(existing_mask).astype(bool)

        intersection = np.logical_and(
            new_mask, existing_mask
        ).sum()

        union = np.logical_or(
            new_mask, existing_mask
        ).sum()

        if union == 0:
            continue

        iou = intersection / union

        if iou >= threshold:
            return True

    return False

# ----------------------------------------
# SAVE OBJECT AND METADATA
# ----------------------------------------

def save_object(name, mask, confidence=None):
    global saved_count

    mask = np.asarray(mask, dtype=bool)

    if mask.shape != (H, W) or not mask.any():
        print("Invalid or empty mask.")
        return False

    ys, xs = np.where(mask)

    x1, x2 = int(xs.min()), int(xs.max()) + 1
    y1, y2 = int(ys.min()), int(ys.max()) + 1

    rgba = np.dstack((image, mask.astype(np.uint8) * 255))
    obj = Image.fromarray(rgba, "RGBA")
    obj = obj.crop((x1, y1, x2, y2))

    safe_name = "".join(
        c if c.isalnum() or c in "_-" else "_"
        for c in name.lower().replace(" ", "_")
    )

    filename = f"{safe_name}_{saved_count + 1}"

    obj.save(os.path.join(OUTPUT_DIR, filename + ".png"))

    Image.fromarray(
        mask.astype(np.uint8) * 255
    ).save(os.path.join(OUTPUT_DIR, filename + "_mask.png"))

    metadata = {
        "objectID": filename,
        "type": name,
        "x": x1,
        "y": y1,
        "width": x2 - x1,
        "height": y2 - y1,
        "confidence": confidence,
        "objectImage": filename + ".png",
        "maskImage": filename + "_mask.png"
    }

    with open(
        os.path.join(OUTPUT_DIR, filename + ".json"),
        "w",
        encoding="utf-8"
    ) as f:
        json.dump(metadata, f, indent=4)

    saved_count += 1
    print(f"Saved {name}: {filename}.png")

    return True


# ----------------------------------------
# 1. AUTOMATIC YOLO DETECTION
# ----------------------------------------
saved_masks = []
print("Running YOLO detection...")

yolo = YOLO(YOLO_MODEL)

results = yolo.predict(
    source=IMAGE_PATH,
    conf=0.25,
    retina_masks=True,
    verbose=False
)

detected_names = set()

for result in results:
    if result.masks is None:
        continue

    masks = result.masks.data.cpu().numpy()

    for i, box in enumerate(result.boxes):
        name = result.names[int(box.cls[0])]
        confidence = float(box.conf[0])

        mask = masks[i]

        if mask.shape != (H, W):
            mask = cv2.resize(
                mask.astype(np.uint8),
                (W, H),
                interpolation=cv2.INTER_NEAREST
            )

        if save_object(name, mask > 0, confidence):
             detected_names.add(name.lower())
             saved_masks.append((mask > 0).copy())

print("Automatic detection completed.")


# ----------------------------------------
# 2. LOAD SAM 2
# ----------------------------------------

print("Loading SAM 2...")

device = "cuda" if torch.cuda.is_available() else "cpu"

sam_model = build_sam2(
    SAM_CONFIG,
    SAM_CHECKPOINT,
    device=device
)

predictor = SAM2ImagePredictor(sam_model)
predictor.set_image(image)

print("Ready for manual object selection.")


# ----------------------------------------
# 3. INTERACTIVE KEEP / STOP WINDOW
# ----------------------------------------

WINDOW = "NestCraft - Select Objects"

points = []
labels = []
current_mask = None
current_score = None
manual_number = 0
stop_selection = False

# Display image at its original dimensions.
# The image should fit your screen for accurate clicking.
base = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)



def draw_interface():
    display = base.copy()

    # Show the current SAM 2 mask.
    if current_mask is not None:
        overlay = display.copy()
        overlay[current_mask] = (0, 200, 0)

        display = cv2.addWeighted(
            display, 0.65, overlay, 0.35, 0
        )

        contours, _ = cv2.findContours(
            current_mask.astype(np.uint8),
            cv2.RETR_EXTERNAL,
            cv2.CHAIN_APPROX_SIMPLE
        )

        cv2.drawContours(
            display, contours, -1, (0, 255, 0), 2
        )

    # KEEP button
    cv2.rectangle(
        display, (10, 10), (140, 55), (30, 150, 30), -1
    )
    cv2.putText(
        display, "KEEP", (35, 41),
        cv2.FONT_HERSHEY_SIMPLEX, 0.9,
        (255, 255, 255), 2
    )

    # STOP button
    cv2.rectangle(
        display, (150, 10), (280, 55), (0, 0, 200), -1
    )
    cv2.putText(
        display, "STOP", (175, 41),
        cv2.FONT_HERSHEY_SIMPLEX, 0.9,
        (255, 255, 255), 2
    )

    # Positive and negative selection points
    for (x, y), label in zip(points, labels):
        color = (0, 255, 0) if label == 1 else (0, 0, 255)
        cv2.circle(display, (x, y), 5, color, -1)

    cv2.imshow(WINDOW, display)


def mouse_callback(event, x, y, flags, param):
    global current_mask, current_score
    global points, labels, manual_number, stop_selection

    if event not in (cv2.EVENT_LBUTTONDOWN, cv2.EVENT_RBUTTONDOWN):
        return

    # KEEP button
    
    # KEEP button
    if event == cv2.EVENT_LBUTTONDOWN and 10 <= x <= 140 and 10 <= y <= 55:
        if current_mask is None:
            print("Select an object before clicking KEEP.")
            return

        if is_duplicate_mask(current_mask, saved_masks):
            print("Duplicate object detected. Not saving again.")
        else:
            name = f"manual_object_{manual_number + 1}"

            if save_object(name, current_mask, current_score):
                saved_masks.append(current_mask.copy())
                manual_number += 1
                print("Object saved successfully.")

        # Reset selection
        points.clear()
        labels.clear()
        current_mask = None
        current_score = None

        print("Select another object or click STOP.")
        draw_interface()
        return


    # STOP button
    if event == cv2.EVENT_LBUTTONDOWN and 150 <= x <= 280 and 10 <= y <= 55:
        stop_selection = True
        return

   # Click on image:
# Left-click = select a new object
# Right-click = mark background

    if event == cv2.EVENT_LBUTTONDOWN:
    # Clear the previous object's selection
     points.clear()
     labels.clear()

    # Start selecting the new object
     points.append([x, y])
     labels.append(1)

    elif event == cv2.EVENT_RBUTTONDOWN:
    # Add a background point for the current object
     points.append([x, y])
     labels.append(0)

    try:
        masks, scores, _ = predictor.predict(
            point_coords=np.array(points, dtype=np.float32),
            point_labels=np.array(labels, dtype=np.int32),
            multimask_output=True
        )

        best = int(np.argmax(scores))
        current_mask = masks[best].astype(bool)
        current_score = float(scores[best])

        print(f"Preview updated. Score: {current_score:.3f}")
        print("Click KEEP to save, or STOP to finish.")

    except Exception as e:
        print("Segmentation error:", e)

    draw_interface()


# ----------------------------------------
# 4. START MANUAL SELECTION WINDOW
# ----------------------------------------

cv2.namedWindow(WINDOW, cv2.WINDOW_NORMAL)
cv2.resizeWindow(WINDOW, W, H)
cv2.setMouseCallback(WINDOW, mouse_callback)

draw_interface()

print("\nManual detection is ready.")
print("Left-click an object to select it.")
print("Right-click to mark unwanted areas.")
print("Click KEEP to save or STOP to finish.")

while not stop_selection:
    key = cv2.waitKey(50)

    if key == 27:  # ESC key
        stop_selection = True

cv2.destroyAllWindows()

# ----------------------------------------
# 5. FINISH
# ----------------------------------------

print("\nProcessing completed.")
print(f"Saved {saved_count} objects in: {OUTPUT_DIR}")
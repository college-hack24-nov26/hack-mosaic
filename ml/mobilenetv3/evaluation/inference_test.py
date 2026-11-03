"""
Pashu Wani — TFLite Inference Verification Test
Supports both Bovine (Cattle/Cow) and Avian (Poultry) Disease Models.
"""

import os
import sys
import argparse
import numpy as np
from PIL import Image
import tensorflow as tf

def run_inference(image_path, species="bovine", model_path=None, labels_path=None):
    if species.lower() in ["bovine", "cattle", "cow"]:
        if model_path is None:
            model_path = r"c:\HA_022\ml\image_classifier\artifacts\bovine_disease_classifier.tflite"
            if not os.path.exists(model_path):
                model_path = r"c:\HA_022\ml\models\bovine_disease_classifier.tflite"
        if labels_path is None:
            labels_path = r"c:\HA_022\ml\shared\label_maps\bovine_labels.txt"
            if not os.path.exists(labels_path):
                labels_path = r"c:\HA_022\ml\models\bovine_labels.txt"
    else:
        if model_path is None:
            model_path = r"c:\HA_022\ml\image_classifier\artifacts\livestock_disease_classifier.tflite"
            if not os.path.exists(model_path):
                model_path = r"c:\HA_022\ml\models\mobilenetv3_model.tflite"
        if labels_path is None:
            labels_path = r"c:\HA_022\ml\shared\label_maps\disease_labels.txt"
            if not os.path.exists(labels_path):
                labels_path = r"c:\HA_022\ml\models\labels.txt"

    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model not found at: {model_path}")
    if not os.path.exists(labels_path):
        raise FileNotFoundError(f"Labels not found at: {labels_path}")

    # Load labels
    with open(labels_path, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]

    # Load TFLite model and allocate tensors
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Preprocessing (224x224 RGB, scaled to [-1.0, 1.0]):
    img = Image.open(image_path).convert("RGB")
    img = img.resize((224, 224), Image.BILINEAR)
    img_array = np.array(img, dtype=np.float32)
    img_array = (img_array / 127.5) - 1.0
    input_data = np.expand_dims(img_array, axis=0)

    # Set input tensor & invoke
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

    # Get output probabilities
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]
    predicted_idx = int(np.argmax(output_data))
    confidence = float(output_data[predicted_idx])
    predicted_class = labels[predicted_idx] if predicted_idx < len(labels) else f"Class_{predicted_idx}"

    print(f"\n==========================================")
    print(f"TFLite Inference Result ({species.upper()} Model)")
    print(f"File: {os.path.basename(image_path)}")
    print(f"Predicted Class: {predicted_class}")
    print(f"Confidence: {confidence:.4f} ({confidence*100:.2f}%)")
    print("Class Probabilities:")
    for i, lbl in enumerate(labels):
        prob = float(output_data[i]) if i < len(output_data) else 0.0
        print(f"  [{lbl}]: {prob:.4f} ({prob*100:.2f}%)")
    print(f"Disclaimer: Preliminary AI screening only. Not a veterinary diagnosis.")
    print(f"==========================================\n")

    return {
        "species": species,
        "predicted_class": predicted_class,
        "confidence": confidence,
        "probabilities": {lbl: float(output_data[i]) for i, lbl in enumerate(labels)}
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TFLite Livestock Disease Inference Test")
    parser.add_argument("image", help="Path to input livestock image")
    parser.add_argument("--species", default="bovine", choices=["bovine", "avian", "poultry", "cattle", "cow"],
                        help="Livestock species model to invoke (default: bovine)")
    args = parser.parse_args()

    run_inference(args.image, species=args.species)

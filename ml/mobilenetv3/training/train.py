"""
Pashu Wani — MobileNetV3-Small Training Pipeline
Livestock Disease Image Classification for Edge TFLite Inference.
"""

import os
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input
from sklearn.metrics import classification_report, confusion_matrix

def train_and_export():
    dataset_dir = r"c:\HA_022\ml\datasets\raw\poultry_diseases\Chicken-fecal-images"
    models_dir = r"c:\HA_022\ml\models"
    reports_dir = r"c:\HA_022\ml\reports"
    os.makedirs(models_dir, exist_ok=True)
    os.makedirs(reports_dir, exist_ok=True)

    img_size = (224, 224)
    batch_size = 16

    print(f"Loading dataset from: {dataset_dir}")
    train_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir,
        validation_split=0.2,
        subset="training",
        seed=42,
        image_size=img_size,
        batch_size=batch_size,
        label_mode="categorical"
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir,
        validation_split=0.2,
        subset="validation",
        seed=42,
        image_size=img_size,
        batch_size=batch_size,
        label_mode="categorical"
    )

    class_names = train_ds.class_names
    print(f"Class names detected: {class_names}")

    # Save labels.txt
    labels_path = os.path.join(models_dir, "labels.txt")
    with open(labels_path, "w", encoding="utf-8") as f:
        for c in class_names:
            f.write(f"{c}\n")
    print(f"Saved {labels_path}")

    # Shared label map copy
    shared_labels_path = r"c:\HA_022\ml\shared\label_maps\disease_labels.txt"
    os.makedirs(os.path.dirname(shared_labels_path), exist_ok=True)
    with open(shared_labels_path, "w", encoding="utf-8") as f:
        for c in class_names:
            f.write(f"{c}\n")

    # Data augmentation pipeline
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.15),
        layers.RandomZoom(0.1),
    ])

    train_ds = train_ds.map(lambda x, y: (data_augmentation(x, training=True), y))
    train_ds = train_ds.map(lambda x, y: (preprocess_input(x), y)).prefetch(tf.data.AUTOTUNE)
    val_ds = val_ds.map(lambda x, y: (preprocess_input(x), y)).prefetch(tf.data.AUTOTUNE)

    # Base MobileNetV3-Small
    base_model = MobileNetV3Small(
        input_shape=(224, 224, 3),
        include_top=False,
        weights="imagenet",
        pooling="avg"
    )
    base_model.trainable = False

    inputs = tf.keras.Input(shape=(224, 224, 3))
    x = base_model(inputs, training=False)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(len(class_names), activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )

    print("\n--- Phase 1: Training Classification Head ---")
    callbacks = [
        tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True)
    ]
    model.fit(train_ds, validation_data=val_ds, epochs=15, callbacks=callbacks)

    print("\n--- Phase 2: Fine-Tuning Top Layers ---")
    base_model.trainable = True
    # Freeze bottom layers
    for layer in base_model.layers[:-20]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )
    model.fit(train_ds, validation_data=val_ds, epochs=10, callbacks=callbacks)

    # Evaluation
    print("\n--- Evaluation on Validation Split ---")
    y_true = []
    y_pred = []
    for imgs, lbls in val_ds:
        preds = model.predict(imgs)
        y_true.extend(np.argmax(lbls.numpy(), axis=1))
        y_pred.extend(np.argmax(preds, axis=1))

    report = classification_report(y_true, y_pred, target_names=class_names, output_dict=True)
    report_text = classification_report(y_true, y_pred, target_names=class_names)
    cm = confusion_matrix(y_true, y_pred).tolist()

    print(report_text)
    with open(os.path.join(reports_dir, "mobilenetv3_evaluation.txt"), "w") as f:
        f.write(report_text)
        f.write(f"\nConfusion Matrix:\n{cm}\n")

    # Save Keras model
    keras_model_path = os.path.join(models_dir, "mobilenetv3_model.keras")
    model.save(keras_model_path)
    print(f"Keras model saved to {keras_model_path}")

    # Convert to TFLite directly from Keras model
    print("\n--- Exporting to TensorFlow Lite ---")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    tflite_path = os.path.join(models_dir, "mobilenetv3_model.tflite")
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite exported: {tflite_path} ({len(tflite_model)} bytes)")

    # Also place in ml/image_classifier/artifacts for Flutter integration
    artifacts_tflite = r"c:\HA_022\ml\image_classifier\artifacts\livestock_disease_classifier.tflite"
    os.makedirs(os.path.dirname(artifacts_tflite), exist_ok=True)
    with open(artifacts_tflite, "wb") as f:
        f.write(tflite_model)

    # Model metadata
    metadata = {
        "model_name": "PashuWani_MobileNetV3_Small",
        "version": "1.0.0",
        "classes": class_names,
        "input_shape": [1, 224, 224, 3],
        "input_dtype": "float32",
        "preprocessing": "MobilenetV3: (pixel_val / 127.5) - 1.0",
        "output_shape": [1, len(class_names)],
        "output_interpretation": "Softmax probabilities",
        "metrics": report,
        "confusion_matrix": cm,
        "disclaimer": "Preliminary AI screening only. Not a definitive veterinary diagnosis."
    }
    with open(os.path.join(models_dir, "mobilenetv3_metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)
    artifacts_meta = r"c:\HA_022\ml\image_classifier\artifacts\model_metadata.json"
    with open(artifacts_meta, "w") as f:
        json.dump(metadata, f, indent=2)
    print("Metadata written to mobilenetv3_metadata.json and artifacts")

if __name__ == "__main__":
    train_and_export()


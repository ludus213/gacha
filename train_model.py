import os
import cv2
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

def load_images_from_folder(folder):
    images = []
    for filename in os.listdir(folder):
        img = cv2.imread(os.path.join(folder,filename))
        if img is not None:
            images.append(img)
    return images

def main():
    data = []
    labels = []

    captcha_path = 'images/captcha'
    class_names = sorted(os.listdir(captcha_path))

    for i, class_name in enumerate(class_names):
        class_path = os.path.join(captcha_path, class_name)
        images = load_images_from_folder(class_path)
        for img in images:
            img = cv2.resize(img, (150, 150))
            data.append(img)
            labels.append(i)

    data = np.array(data) / 255.0
    labels = np.array(labels)

    X_train, X_test, y_train, y_test = train_test_split(data, labels, test_size=0.2, random_state=42)

    model = tf.keras.models.Sequential([
        tf.keras.layers.Conv2D(32, (3, 3), activation='relu', input_shape=(150, 150, 3)),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Conv2D(64, (3, 3), activation='relu'),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Conv2D(128, (3, 3), activation='relu'),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dense(len(class_names), activation='softmax')
    ])

    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])

    model.fit(X_train, y_train, epochs=10, validation_data=(X_test, y_test))

    model.save('captcha_model.h5')

if __name__ == '__main__':
    main()

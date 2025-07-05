# AllEars
Gamified Digital Pet for Task Routine and AI Listener for Everyday Life. 

<p align="center">
  <img src="AllEars/assets/img/allears.png" width="50%"/>
</p>
---

## Features

### Digital Pet 
Pet Companion for Routine Gamification
AllEars transforms your daily routines into a rewarding and playful experience through a virtual pet companion that grows with you. No pressure, no punishment, just a cute, uplifting presence that celebrates consistency, **one task at a time**.

### AI Listener
Sometimes, you just need to talk and AllEars is ready to listen. With a built-in AI companion powered by cutting-edge language models, you can freely express your thoughts, emotions, and questions in a **judgment-free space** . Whether you're venting after a long day, reflecting on life, or simply need to be heard, AllEars offers a private and empathetic digital ear. There’s no need to sign up, no pressure to phrase things "perfectly," and no fear of being misunderstood.


## Installation Guide (for Users)

### Installing the AllEars Mobile App (APK)
To use AllEars on your Android device:

1. Download the APK file
Head over to the Releases section of this repository and download the latest .apk file.

2. Allow installation from unknown sources
Since this app isn't from the Play Store, Android needs your permission to install it:

    Go to your phone's Settings > Security (or Apps & Notifications > Special app access)

    Enable Install unknown apps for your browser or file manager.

3. Install the APK
Locate the downloaded file (usually in your Downloads folder) and tap it to begin installation.

4. Ensure a stable internet connection
The app connects with the pet minigame online, so make sure your phone has a good Wi-Fi or mobile data connection.

 2. Setting Up the AllEarsServer (AI Backend)
To use the AI Listener feature, you’ll need to run the AllEarsServer on your computer.


### Installing AI AllEarsServer

1. Download the AllEarsServer .zip file
Visit the Releases section and download the latest version of AllEarsServer.zip (Windows only for now).

2. Extract the folder
Right-click the ZIP file and choose Extract All..., then extract it to any folder you like (e.g., Desktop or Documents).

3. Input Your Gemini API Key
Paste your secret *secret* API Key and press enter **3 TIMES** or until the API Key is initialized.
You can change it by modifying `.allears_config.json`

4. Run the server
Open the extracted folder and double-click AllEarsServer.exe. The server should start running, and a window will appear showing your connection status and QR code.

- Connect your Android app to the server

- Make sure your phone and your computer are connected to the same Wi-Fi network.

- Open the AllEars mobile app.

- Tap the chat bubble icon at the bottom of the screen.

Scan the QR code shown on your computer screen, just like how WhatsApp Web works!!



## Developer's Guides


Welcome, developers! AllEars is a modular project composed of three main components. You can work on each module independently or run them together for a full-stack experience.

---

### Project Structure Overview

```
AllEars/
├── /AllEars        # Flutter app (mobile client)
├── /backend        # FastAPI server with NLP and AI Listener
└── /minigame       # Kaplay.JS digital pet game (web-based)
```

---

### 1. Setting Up the Flutter Mobile App (`/AllEars`)

This is the heart of the AllEars mobile experience. It communicates with the FastAPI backend and embeds the digital pet minigame.

#### 🔧 Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) 

#### 📦 Installation

```bash
cd AllEars
flutter pub get
```

#### ▶️ Run the App

To run on your connected device:

```bash
flutter run
```

Ensure the device or emulator is on the **same network** as the backend server (see below).

---

### 2. Setting Up the Backend AI Server (`/backend`)

This is the FastAPI server that powers the non-judgmental AI Listener, including NLP pipelines and QR-based session linking.

#### 🔧 Prerequisites

* Python 3.10 or higher
* Virtual environment (recommended)

#### 📦 Installation

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### ▶️ Run the Server

```bash
python main.py
```

This starts the backend server and generates a QR code for client pairing. The server listens for connections from the mobile app.

> 💡 For packaging into `.exe`, use `pyinstaller`

---

### 3. Running the Digital Pet Mini-Game (`/minigame`)

The `/minigame` folder contains the browser-based pet system powered by **Kaplay.JS** (or Kaboom.JS).

#### 🔧 Prerequisites

* [Node.js](https://nodejs.org/) (v16+)
* A browser

#### 📦 Installation

```bash
cd minigame
npm install
```

#### ▶️ Run the Game

```bash
npm run dev
```

This launches the pet minigame in your browser. Eventually, this is embedded inside the mobile app as a WebView or direct render.

---

### 🔗 Connecting the Components

To see the whole system in action:

* Make sure **AllEarsServer (backend)** is running.
* Ensure **Flutter app** is connected to the same network.
* Run **minigame** if you want to test pet interactions separately.

---

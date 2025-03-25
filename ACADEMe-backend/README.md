# ACADEMe-Backend 🎓📚  
**AI-Powered Student Tracking & Conversational Assistant System**  

ACADEMe-Backend is a **FastAPI-based** backend system for tracking student progress, analyzing performance, managing course content, and providing AI-driven conversational support. It integrates **Google Gemini AI**, **LibreTranslate**, and **Whisper** for personalized insights, multilingual interactions, and multimedia processing. Supports **role-based access control (RBAC)** with **admin and student roles**.  

---

## 🛠️ Features  

### ✅ Authentication & Security  
- JWT-based authentication with access tokens  
- Firebase Authentication for secure user login  
- Password hashing with bcrypt  

### ✅ User Roles & Access Control  
- **Students** can enroll, access courses, take quizzes, track progress, and interact with AI.  
- **Admins** (identified via email) can **create, update, delete** courses, topics, quizzes, and manage all content.  

### ✅ Course & Content Management  
**Hierarchical Course Structure:**  
📚 **Courses** → 📖 **Topics** → 🔍 **Subtopics** → 📂 **Materials**  
- **Materials** support multiple formats: `text`, `images`, `audio`, `video`, `documents`, `links`.  

### ✅ AI-Driven Analytics & Conversational Support  
- **Google Gemini AI** for:  
  - 📊 Performance analysis & graphical reports  
  - 🎯 Personalized learning recommendations  
  - 🧠 **Multimodal AI Conversations**: Process `text`, `documents`, `images`, `audio`, and `video` queries.  
  - 🌍 **Multilingual Support**: Translate responses using LibreTranslate.  
- **Whisper AI** for audio/video transcription.  
- **On-demand insights** to reduce Firestore read costs.  

### ✅ Student Progress Tracking  
- **Stores progress** in Firestore with graphical reports (Study Time vs. Days).  

### ✅ Quizzes & Assessments  
- Dynamic quiz management under topics/subtopics.  
- Questions stored within quizzes for easy API fetching.  

### ✅ Discussion Forum  
- Thread-based discussions for course topics.  

### ✅ File Storage  
- **Firestore** for structured data  
- **Cloudinary** for media files  

### ✅ Scalability & Performance  
- Modular FastAPI architecture with async support.  

---

## 🚀 Installation & Setup  

### 1️⃣ Clone the Repository  
```bash
git clone https://github.com/HappySR/ACADEMe-backend.git
cd ACADEMe-backend
```

### 2️⃣ Set Up Virtual Environment  
```bash
python3 -m venv venv
source venv/bin/activate  # On macOS/Linux
venv\Scripts\activate  # On Windows
```

### 3️⃣ Install Dependencies  
```bash
pip install -r requirements.txt
```

### 4️⃣ Configure Environment Variables  
Create a `.env` file:  
```ini
# Authentication & Firebase
JWT_SECRET_KEY=your_jwt_secret_key
FIREBASE_CRED_PATH=/path/to/firebase/credentials.json

# AI Services
GOOGLE_GEMINI_API_KEY=your_gemini_api_key
LIBRETRANSLATE_URL=http://localhost:5000  # LibreTranslate instance

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### 5️⃣ Firebase & Cloudinary Setup Guide
#### **1. Firebase Service Account Credentials**  
1. Download your Firebase Admin SDK credentials:  
   - Go to [Firebase Console](https://console.firebase.google.com/) > Your Project > ⚙️ **Project Settings** > **Service Accounts**.  
   - Under **Firebase Admin SDK**, click **Generate New Private Key** (JSON file).  

2. Set the environment variable:  
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   ```  
   To make it permanent:  
   - **Bash**: Add to `~/.bashrc`  
     ```bash
     echo 'export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"' >> ~/.bashrc
     source ~/.bashrc
     ```  
   - **Zsh**: Add to `~/.zshrc`  
     ```zsh
     echo 'export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"' >> ~/.zshrc
     source ~/.zshrc
     ```  

#### **2. Cloudinary Environment Variables**  
Ensure your `.env` file has:  
```plaintext
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```  
Then load them:  
```bash
export $(grep -v '^#' .env | xargs)
```  
Verify with:  
```bash
printenv | grep CLOUDINARY  # Should show your keys
```

### 6️⃣ Start the Server  
```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```
API available at **http://127.0.0.1:8000**

## 🐋 Docker Setup  
```bash
# Build
docker build -t academe-backend .

# Run (mount Firebase credentials)
docker run -d -p 8000:8000 \
  -v $(pwd)/firebase/firebase-key.json:/app/firebase-key.json \
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-key.json \
  academe-backend
```

---

## 📜 License  
MIT License  

---

## 👨‍💻 Author  
Developed by **Team VISI0N**  

---

## 🌟 Support & Contribution  
- Report issues or submit PRs via GitHub.
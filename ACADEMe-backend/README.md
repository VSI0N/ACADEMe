# ACADEMe-Backend 🎓📚  
**AI-Powered Student Tracking System**  

ACADEMe-Backend is a **FastAPI-based** backend system for tracking student progress, analyzing performance, and managing course content dynamically. It integrates **Google Gemini AI** for personalized insights and supports **role-based access control (RBAC)** with **admin and student roles**.  

---

## 🛠️ Features  

### ✅ Authentication & Security  
- JWT-based authentication with access tokens  
- Firebase Authentication for secure user login  
- Password hashing with bcrypt  

### ✅ User Roles & Access Control  
- **Students** can enroll, access courses, take quizzes, and track progress.  
- **Admins** (identified via email) can **create, update, delete** courses, topics, subtopics, quizzes, and study materials.  

### ✅ Course & Content Management  
**Hierarchical Course Structure:**  
📚 **Courses** → 📖 **Topics** → 🔍 **Subtopics** → 📂 **Materials**  
- **Materials** support multiple formats: `text`, `images`, `audio`, `video`, `documents`, `links`.  

### ✅ AI-Driven Student Analytics  
Uses **Google Gemini AI** for:  
- 📊 **Performance analysis** (graphs & insights)  
- 🎯 **Personalized learning recommendations**  
- **On-demand AI insights** to reduce Firestore read costs  

### ✅ Student Progress Tracking  
- **Stores progress** in Firestore  
- **Generates graphical reports** (📊 marks vs. chapters)  

### ✅ Quizzes & Assessments  
- **Quizzes are added under topics & subtopics**.  
- **Questions are stored inside quizzes** (not in a separate collection).  
- **Fetch quizzes & questions dynamically** via API.  

### ✅ Discussion Forum  
- Students can discuss topics via a **forum system**.  

### ✅ File Storage  
- **Firestore** for structured data  
- **Cloudinary** for `images`, `audio`, `videos`, and `documents`  

### ✅ Unit Testing  
- Includes tests for **authentication, user creation, and other APIs**  

### ✅ Scalability & Performance  
- Modular structure with **services, routes, and models**  

---

## 📂 Project Structure  
```
ACADEME-BACKEND/
│── __pycache__/
│── config/
│   ├── cloudinary_config.py
│   ├── settings.py
│── generate_secret_keys/
│   ├── secret_key_generation.py
│── models/
│   ├── __pycache__/
│   ├── ai_model.py
│   ├── course_model.py
│   ├── discussion_model.py
│   ├── material_model.py
│   ├── progress_model.py
│   ├── quiz_model.py
│   ├── topic_model.py
│   ├── user_model.py
│── routes/
│   ├── __pycache__/
│   ├── __init__.py
│   ├── ai_analytics.py
│   ├── courses.py
│   ├── discussions.py
│   ├── material_routes.py
│   ├── quizzes.py
│   ├── student_progress.py
│   ├── topics.py
│   ├── users.py
│── services/
│   ├── __pycache__/
│   ├── ai_service.py
│   ├── auth_service.py
│   ├── course_service.py
│   ├── discussion_service.py
│   ├── material_service.py
│   ├── progress_service.py
│   ├── quiz_service.py
│   ├── topic_service.py
│── utils/
│   ├── __pycache__/
│   ├── auth.py
│   ├── class_filter.py
│   ├── cloudinary_service.py
│   ├── firestore_helpers.py
│── venv/
│── .env
│── .gitignore
│── firebase.py
│── main.py
│── README.md
|── requirements.txt
```

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
Create a `.env` file in the root directory:  

```ini
# Authentication Keys
JWT_SECRET_KEY=your_jwt_secret_key # You can generate it by running secret_key_generation.py which is under generate_secret_keys folder

# Firebase
FIREBASE_CRED_PATH=/path/to/firebase/credentials.json

# Google AI
GOOGLE_GEMINI_API_KEY=your_gemini_api_key

# Cloudinary (for file uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### 5️⃣ Set Up Firebase Credentials: You need to ensure that you are using Firebase's service account credentials, not just Google Cloud's default credentials.

1. Download your Firebase Admin SDK credentials (JSON file) from the Firebase Console:
2. Go to the Firebase Console.
3. Select your project.
4. Navigate to Project Settings > Service Accounts.
5. Under Firebase Admin SDK, click Generate New Private Key.
This will download a JSON file with your service account credentials.
Set the GOOGLE_APPLICATION_CREDENTIALS Environment Variable: Set the environment variable to point to the downloaded Firebase service account credentials file:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-file.json"
```
Replace /path/to/your/service-account-file.json with the actual path to the Firebase JSON key file you downloaded.

#### You can make this change permanent by adding the export statement to your shell profile:

##### For bash: Add it to ~/.bashrc:

```bash
echo 'export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-file.json"' >> ~/.bashrc
source ~/.bashrc
```

##### For zsh: Add it to ~/.zshrc:
```bash
echo 'export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-file.json"' >> ~/.zshrc
source ~/.zshrc
```

#### Run the following command:
```bash
printenv | grep CLOUDINARY
```
If the above command returns nothing then run the following command to load the CLOUDINARY api keys:
```bash
export $(grep -v '^#' .env | xargs)
```
After running the above command, again check if the following command returns something:
```bash
printenv | grep CLOUDINARY
```
If it returns CLOUDINARY keys then you are good to go...

### 6️⃣ Start the Server  
```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```
Your API will be available at **http://127.0.0.1:8000**

## Installation by Docker

### 1️⃣ Build the Docker Container

After cloning this repository and creating the .env file in ACADEMe-backend, you can run the following commands:

```bash
docker build -t academe-backend .
```

### 2️⃣ Run the Docker Container

You can download the firebase-key.json file from Firebase Console > Project Overview > Project Settings > Service accounts and then store it in firebase folder of ACADEMe-backend and then run the following command after replacing firebase-key.json with your actual firebase-key.json file.

```bash
docker run -d -p 8000:8000 \
  -v $(pwd)/firebase/firebase-key.json:/app/firebase-key.json \
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-key.json \
  academe-backend
```

Your API will be available at **http://localhost:8000**

#### To stop the Docker Container, you can run the following command:

```bash
docker stop <container_id>
```

#### To start the Docker Container, you can run the following command:

```bash
docker start <container_id>
```

---

## 🛠️ API Endpoints  

### **Authentication**  
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | `/auth/register` | Register a new student |
| POST | `/auth/login` | Login with Firebase |
| POST | `/auth/refresh` | Refresh access token |

---

### **Course Management (Admin Only)**  
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | `/courses/` | Create a course |
| GET | `/courses/` | Get all courses |
| PUT | `/courses/{course_id}` | Update a course |
| DELETE | `/courses/{course_id}` | Delete a course |

---

### **Topic & Subtopic Management**  
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | `/courses/{course_id}/topics/` | Add a topic |
| GET | `/courses/{course_id}/topics/` | Get topics |
| POST | `/courses/{course_id}/topics/{topic_id}/subtopics/` | Add a subtopic |

---

### **Study Materials**  
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | `/courses/{course_id}/topics/{topic_id}/materials/` | Add material to topic |
| POST | `/courses/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/materials/` | Add material to subtopic |

---

### **Quizzes & Assessments**  
| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | `/courses/{course_id}/topics/{topic_id}/quizzes/` | Create a quiz |
| GET | `/courses/{course_id}/topics/{topic_id}/quizzes/` | Get all quizzes for a topic |
| GET | `/courses/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/` | Get all quizzes for a subtopic |
| POST | `/courses/{course_id}/topics/{topic_id}/quizzes/{quiz_id}/questions/` | Add a question to a quiz |
| GET | `/courses/{course_id}/topics/{topic_id}/quizzes/{quiz_id}/questions/` | Get all questions for a quiz (Topic Level) |
| GET | `/courses/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/{quiz_id}/questions/` | Get all questions for a quiz (Subtopic Level) |

---

### **Student Progress & AI Analytics**  
| Method | Endpoint | Description |
|--------|---------|-------------|
| GET | `/students/progress/{student_id}` | Fetch student progress |
| GET | `/students/analytics/{student_id}` | Get AI-powered recommendations |

---

## 📊 AI Analytics & Student Progress Tracking  
- **Performance analysis** using AI (**Google Gemini**)  
- **Data stored** in Firestore (for efficiency)  
- **Graphical reports** (📊 Marks vs. Chapters)  

---

## ✅ **Admin Access Control**  
**Admin emails** are stored separately. If an admin logs in, they can manage:  
✅ **Courses**  
✅ **Topics & Subtopics**  
✅ **Quizzes & Questions**  
✅ **Study Materials**  
✅ **Student Data & AI Analytics**  

---

## 📜 License  
This project is licensed under the **MIT License**.  

---

## 👨‍💻 Author  
Developed by **Team VISI0N**  

---

## 🌟 Support & Contribution  
- **Found a bug?** Raise an issue  
- **Want to improve something?** Open a PR  

---

# **ASKMe Backend** 🧠💬  

This is the backend service for **ASKMe**, a powerful AI-driven conversational assistant that supports **text, documents, audio, and video processing**. It integrates **Google Gemini AI**, **LibreTranslate**, and **Whisper** to provide intelligent responses, translations, and transcriptions.

## 🚀 Features  
- ✅ **Text Processing**: Understands and responds to text-based queries.  
- 📄 **Document Analysis**: Extracts and processes text from **PDF, DOCX, and TXT** files.  
- 🖼 **Image Processing**: Analyzes images, extracts text if applicable, understands visual content, and generates insights using **Gemini AI**.
- 🎙 **Audio Processing**: Transcribes and analyzes audio files using **Whisper AI**.  
- 🎥 **Video Processing**: Analyzes the video, and processes it via **Gemini AI**.  
- 🌍 **Translation Support**: Detects language and translates responses using **LibreTranslate**.  
- 🔥 **FastAPI-based API**: A robust, asynchronous backend built with **FastAPI**.  

---

## 📌 **Installation**  

### 1️⃣ **Clone the Repository**  
```bash
git clone https://github.com/HappySR/ASKMe-backend.git
cd askme-backend
```

### 2️⃣ Set Up the Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3️⃣ Install Dependencies

```bash
pip install -r requirements.txt
```

```bash
# if error occurs run this:
pip install torch==2.5.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
# then again run the command: pip install -r requirements.txt
````

### 4️⃣ Create a .env File

Create a .env file in the root directory and add the following:

```bash
GOOGLE_GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
LIBRETRANSLATE_URL="http://localhost:5000" # Example LibreTranslate instance
```

## 🛠 Usage
### 1️⃣ Run the Server

```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

This starts the FastAPI server on http://127.0.0.1:8000/.
### 2️⃣ API Endpoints
#### 📌 Process Text Input

```bash
POST /api/process_text
```

    • Description: Processes a text query and returns a response.
    • Request Body:

```bash
{
  "text": "What is the capital of France?",
  "target_language": "fr"
}
```

• Response:

```bash
    {
      "response": "La capitale de la France est Paris."
    }
```

#### 📌 Process Document (PDF, DOCX, TXT)

```bash
POST /api/process_document
```

    • Description: Extracts and processes text from a document.
    • Request Example (Using cURL):

```bash
curl -X 'POST' 'http://127.0.0.1:8000/api/process_document' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@document.pdf' \
  -F 'prompt=Summarize this document' \
  -F 'target_language=en'
```

• Response Example:

```bash
    {
      "response": "This document discusses the effects of climate change on global agriculture."
    }
```

## 🖼 Process Image (JPG, PNG, BMP, WEBP)

```bash
POST /api/process_image
```

• Description: Analyzes an image and provides a response based on the prompt.
• Request Example (Using cURL)

```bash
curl -X 'POST' 'http://127.0.0.1:8000/api/process_image' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@image.jpg' \
  -F 'prompt=Describe this image' \
  -F 'source_lang=auto' \
  -F 'target_lang=en'
```

• Request Body

```bash
{
  "file": "<image file>",
  "prompt": "Describe this image",
  "source_lang": "auto",
  "target_lang": "en"
}
```

• Response Example

```bash
{
  "response": "The image depicts a modern online classroom where a woman is teaching students via a laptop."
}
```

## 🎙 Process Audio (MP3, WAV, FLAC)

```bash
POST /api/process_audio
```

    • Description: Transcribes an audio file and sends it to Gemini AI.
    • Request Example:

```bash
curl -X 'POST' 'http://127.0.0.1:8000/api/process_audio' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@speech.wav' \
  -F 'prompt=Summarize this speech'
```

• Response Example:

```bash
    {
      "response": "The speaker discusses the importance of AI in modern education."
    }
```

## 🎥 Process Video (MP4, MOV, AVI)

```bash
POST /api/process_video
```

    • Description: Extracts audio from a video, transcribes it, and processes it via Gemini AI.
    • Request Example:

```bash
curl -X 'POST' 'http://127.0.0.1:8000/api/process_video' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@lecture.mp4' \
  -F 'prompt=Summarize the key points'
```

• Response Example:

```bash
    {
      "response": "The lecture explains Newton's three laws of motion with examples."
    }
```

## ⚙️ Project Structure

```bash
askme-backend/
│── agents/
│   ├── audio_agent.py                # Handles audio processing
│   ├── document_agent.py             # Handles document analysis
│   ├── image_agent.py                # Handles image processing
│   ├── response_translation_agent.py # Handles response translation
│   ├── stt_agent.py                # Handles speech to text
│   ├── text_agent.py                # Handles text processing
│   ├── video_agent.py                # Handles video processing
│
│── models/
│   ├── message_model.py           # Defines the structure for messages in AI-user communication
│
│── services/
│   ├── gemini_service.py          # Manages communication with Gemini AI
│   ├── libretranslate_service.py  # Handles translation
│   ├── whisper_service.py         # Transcribes speech using Whisper
│
│── utils/
│   ├── language_detection.py      # Language detection
│
│── .env                      # API keys & environment variables
│── app.py                    # Main FastAPI application
│── config.py                 # Configurations
│── LICENSE                   # License
│── README.md                 # This file
│── requirements.txt          # Python dependencies
```

## 🎯 Future Improvements

    🏆 Support for more file types (PPTX, EPUB, etc.)
    🔥 Real-time transcription for live audio/video streams
    🌍 Improved multilingual support
    ⚡ Better caching for faster responses

## 🤝 Contributing

We welcome contributions! 🎉
To contribute:

    Fork the repository
    Create a new branch: git checkout -b feature-name
    Make your changes and commit: git commit -m "Added new feature"
    Push to your branch: git push origin feature-name
    Create a Pull Request

## 📜 License

This project is licensed under the MIT License.
## 🛠 Developed By

💡 Team VISI0N
🚀 Connect with me: [GitHub](https://github.com/HappySR) | [LinkedIn](www.linkedin.com/in/subhajit-roy-dev)

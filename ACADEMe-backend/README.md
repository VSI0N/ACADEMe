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
│   ├── auth.py
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
│   ├── user_service.py
│── tests/
│   ├── test_ai.py
│   ├── test_auth.py
│   ├── test_courses.py
│   ├── test_discussions.py
│   ├── test_progress.py
│   ├── test_questions.py
│   ├── test_quizzes.py
│   ├── test_topics.py
│   ├── test_users.py
│── utils/
│   ├── __pycache__/
│   ├── auth.py
│   ├── class_filter.py
│   ├── cloudinary_service.py
│   ├── firestore_helpers.py
│   ├── validators.py
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

### 6️⃣ Start the Server  
```bash
uvicorn main:app --host 127.0.0.1 --port 8001 --reload
```
Your API will be available at **http://127.0.0.1:8001**  

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
Developed by **Subhajit Roy**  

---

## 🌟 Support & Contribution  
- **Found a bug?** Raise an issue  
- **Want to improve something?** Open a PR  

---
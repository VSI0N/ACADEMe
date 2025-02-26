from fastapi import FastAPI
from routes import users, courses, topics, quizzes, discussions, student_progress, ai_recommendations, progress_visuals

app = FastAPI(title="ACADEMe API", version="1.0")

app.include_router(users.router, prefix="/api")
app.include_router(courses.router, prefix="/api")
app.include_router(topics.router, prefix="/api")
app.include_router(quizzes.router, prefix="/api")
app.include_router(discussions.router, prefix="/api")
app.include_router(student_progress.router, prefix="/api")
app.include_router(ai_recommendations.router, prefix="/api")
app.include_router(progress_visuals.router, prefix="/api")

@app.get("/")
def home():
    return {"message": "ACADEMe API is running!"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001, reload=True)

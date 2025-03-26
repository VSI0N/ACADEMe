# Use an official lightweight Python image
FROM python:3.10-slim  

# Set the working directory inside the container  
WORKDIR /app  

# Copy only essential files first for better caching  
COPY requirements.txt .  

# Install dependencies  
RUN pip install --no-cache-dir -r requirements.txt  

# Copy the Firebase service account file  
# COPY firebase/firebase_service_account.json /firebase/firebase_service_account.json 

# Set the environment variable for Firebase credentials  
ENV GOOGLE_APPLICATION_CREDENTIALS=/firebase/firebase_service_account.json  

# Copy the rest of the application code  
COPY . .  

# Expose the port FastAPI will run on  
EXPOSE 8000  

# Command to run the FastAPI app using Uvicorn  
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

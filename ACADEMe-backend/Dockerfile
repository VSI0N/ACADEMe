# Use an official lightweight Python image
FROM python:3.10-slim  

# Set the working directory inside the container  
WORKDIR /app  

# Copy only essential files first for better caching  
COPY requirements.txt .  

# Install dependencies  
RUN pip install --no-cache-dir -r requirements.txt  

# Copy the rest of the application code  
COPY . .  

# Expose the port FastAPI will run on  
EXPOSE 8000  

# Command to run the FastAPI app using Uvicorn  
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

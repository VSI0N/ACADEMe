import fitz  # PyMuPDF for PDFs
import io
import docx
from fastapi import UploadFile
from services.gemini_service import process_text_with_gemini
from utils.language_detection import detect_language
from services.libretranslate_service import translate_text

async def process_document(file: UploadFile, prompt: str = None):
    """
    Processes uploaded document files (.pdf, .docx, .txt)
    - Detects the language
    - Translates document text & prompt to English (if needed)
    - Sends everything to Gemini for processing
    """
    
    # Read the file
    content = await file.read()
    file_ext = file.filename.split(".")[-1].lower()
    
    print(f"📄 Processing document: {file.filename} (Type: {file_ext})")  # Debugging Log

    extracted_text = ""

    try:
        if file_ext == "pdf":
            doc = fitz.open(stream=content, filetype="pdf")  
            extracted_text = "\n".join([page.get_text("text") for page in doc])

        elif file_ext == "docx":
            doc = docx.Document(io.BytesIO(content))  
            extracted_text = "\n".join([para.text for para in doc.paragraphs])

        elif file_ext == "txt":
            extracted_text = content.decode("utf-8").strip()

        else:
            return {"error": "Unsupported file type. Please upload PDF, DOCX, or TXT."}

        if not extracted_text.strip():
            return {"error": "No readable text found in the document."}

        print(f"✅ Extracted text (first 100 chars): {extracted_text[:100]}...")  # Debugging Log

        # 🔹 Step 2: Detect document language
        detected_lang = detect_language(extracted_text)
        print(f"🌍 Detected Document Language: {detected_lang}")  # Debugging Log

        # 🔹 Step 3: Translate document if not English
        if detected_lang.lower() != "en":
            print("🔄 Translating document to English...")  # Debugging Log
            extracted_text = translate_text(extracted_text, detected_lang, "en")

        # 🔹 Step 4: Translate prompt (if given)
        if prompt and prompt.strip():
            prompt_lang = detect_language(prompt)
            print(f"🌍 Detected Prompt Language: {prompt_lang}")  # Debugging Log
            
            if prompt_lang.lower() != "en":
                print("🔄 Translating prompt to English...")  # Debugging Log
                prompt = translate_text(prompt, prompt_lang, "en")

        # 🔹 Step 5: Prepare Gemini Prompt
        if prompt and prompt.strip():
            final_prompt = f"""
            You are analyzing a document.

            **Task:**
            - Follow the user’s request **strictly**.
            - Do **NOT** add any extra information.
            - Keep responses **concise and relevant**.

            **User Request:** {prompt}

            **Document Content (translated to English):**
            {extracted_text}

            Respond **only** based on the document content and user request.
            """
        else:
            final_prompt = f"""
            The following is a document. Extract and summarize the most relevant details.

            **Document Content (translated to English):**
            {extracted_text}

            Keep your response concise.
            """

        print(f"✅ Final Prompt Sent to Gemini:\n{final_prompt[:200]}...\n")  # Debugging Log

        # 🔹 Step 6: Send to Gemini
        response = await process_text_with_gemini(final_prompt)

        return {"response": response}

    except Exception as e:
        return {"error": f"Error processing document: {str(e)}"}

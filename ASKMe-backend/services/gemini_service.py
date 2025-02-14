import google.generativeai as genai
from config import GEMINI_API_KEY

# Configure Gemini API key
genai.configure(api_key=GEMINI_API_KEY)

# Function to get a response from Gemini 1.5 Flash
def get_gemini_response(prompt: str, chat_history=None, image_path=None) -> str:
    """
    Interacts with Gemini 1.5 Flash to generate a response.
    """
    try:
        # Initialize the Gemini model
        model = genai.GenerativeModel("gemini-1.5-flash")

        # Define system prompt for ASKMe's identity
        systemPrompt = "Your name is ASKMe, an AI assistant developed by Team VISI0N (do not always tell it to others)."

        # Prepare message parts
        parts = [{"text": systemPrompt + "\n\n" + prompt + "\n\n**Please provide a suitable answer.**"}]

        # Include chat history if available
        if chat_history:
            for message in chat_history:
                if isinstance(message, dict) and "content" in message:
                    parts.append({"text": message["content"]})
                else:
                    parts.append({"text": str(message)})

        # If an image is provided, attach it
        if image_path:
            try:
                with open(image_path, "rb") as img_file:
                    image_bytes = img_file.read()

                parts.append({"mime_type": "image/jpeg", "data": image_bytes})  # Adjust mime_type if needed

            except Exception as e:
                print(f"Error loading image: {e}")

        # Send request to Gemini
        response = model.generate_content(parts)

        # Extract text response safely
        if response and hasattr(response, "text"):
            return response.text.strip()  # Strip unwanted spaces/newlines

        return "No response received from Gemini."

    except Exception as e:
        return f"Error in Gemini response: {str(e)}"


# Function for processing text using Gemini
async def process_text_with_gemini(text: str) -> str:
    """
    Processes text using Gemini 1.5 Flash.

    Args:
        text (str): The text to be processed.

    Returns:
        str: Gemini's response to the text.
    """
    prompt = f"""
    You are processing a transcribed speech from an audio recording.

    Task:

        Correct transcription errors, misheard words, and repeated letters.
        Fix grammar, punctuation, and formatting while keeping the original meaning.
        Do NOT change names, locations, or add any new information.
        Do NOT replace words unless absolutely necessary for clarity.
        Do NOT treat this as a cipher, puzzle, or code.
        Do NOT remove important words unless they are clear mistakes.
        If letters are part of an alphabet sequence, keep them as they are.

    Transcribed Text (for your understanding only): {text}

    Important: Do NOT include the corrected transcription in your response. Only provide a brief and relevant response to the prompt without changing the original meaning of the transcription.
    """

    return get_gemini_response(prompt)

import os
import asyncio
import tempfile
import aiofiles
import traceback
from services.gemini_service import get_gemini_response

async def process_video(file, prompt: str = None):
    """
    Processes an uploaded video:
    - Saves it temporarily
    - Sends the video directly to Gemini 2.0 Flash for analysis
    - Returns the relevant response
    """
    print(f"🔍 Received prompt: '{prompt}'")  # Debugging

    if not prompt:
        print("⚠️ Warning: No prompt received!")  # Debugging

    temp_video_path = tempfile.mktemp(suffix=".mp4")

    try:
        # 🔹 Step 1: Save uploaded video as a temp file
        async with aiofiles.open(temp_video_path, "wb") as temp_file:
            while True:
                chunk = await file.read(1024 * 1024)  # ✅ Read in 1MB chunks
                if not chunk:
                    break
                await temp_file.write(chunk)

        print(f"✅ Video saved at: {temp_video_path}")  # Debugging Log

        # 🔹 Step 2: Prepare prompt
        final_prompt = f"""
        You are analyzing a video.

        **Task:**
        - Extract and summarize the most relevant details.
        - Follow the user’s request **strictly** if provided.
        - Keep responses **concise and relevant**.

        **User Request:** {prompt if prompt else "No specific request provided."}

        Respond **only** based on the video and user request.
        """

        print(f"✅ Final Prompt Sent to Gemini:\n{final_prompt[:200]}...\n")  # Debugging Log

        # 🔹 Step 3: Send to Gemini with video file
        response = get_gemini_response(final_prompt, video_path=temp_video_path)  # ✅ Use video instead of image

        return {"response": response}

    except Exception as e:
        error_message = f"❌ Error processing video: {str(e)}\n{traceback.format_exc()}"
        print(error_message)
        return {"error": str(e)}

    finally:
        # Cleanup temporary file
        if os.path.exists(temp_video_path):
            try:
                os.remove(temp_video_path)
                print(f"✅ Deleted temp file: {temp_video_path}")  # Debugging Log
            except Exception as cleanup_error:
                print(f"⚠️ Cleanup error: {cleanup_error}")  # Log cleanup issues

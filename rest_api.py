from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
from functions.model_inference import load_model, predict
import logging

# Initialize the FastAPI app
app = FastAPI()

# Set up logging
logging.basicConfig(level=logging.INFO)

# Request and response structures
class PredictionRequest(BaseModel):
    document: str
    summary: str

class PredictionResponse(BaseModel):
    prediction: int
    probabilities: list

# Load the model and tokenizer
try:
    model, tokenizer = load_model()
except Exception as e:
    raise RuntimeError(f"Error loading model or tokenizer: {e}")

# Root endpoint
@app.get("/")
def read_root():
    return {
        "message": "Document-Level Classification Model API is running!"
    }

# Prediction endpoint
@app.post("/predict", response_model=PredictionResponse)
def predict_endpoint(request: PredictionRequest):
    """
    Handles prediction requests for document-summary pairs, integrating a reusable prediction function.

    Args:
        request (PredictionRequest): Request object containing the document and summary text.

    Returns:
        PredictionResponse: Response object containing the predicted class and probabilities.
    """
    # Validate input
    if not request.document.strip() or not request.summary.strip():
        raise HTTPException(status_code=400, detail="Document and summary cannot be empty.")

    try:
        # Reuse the generic predict function to handle the prediction
        prediction, probabilities = predict(
            text=request.document,
            summary=request.summary,
            model=model,
            tokenizer=tokenizer
        )

        # Convert probabilities tensor to list for the response
        probabilities = probabilities.squeeze().tolist()

        # Log the prediction
        logging.info(f"Prediction: {prediction}, Probabilities: {probabilities}")

        # Return the response object
        return PredictionResponse(prediction=prediction, probabilities=probabilities)

    except Exception as e:
        # Raise an HTTPException with error details
        raise HTTPException(
            status_code=500,
            detail=f"Error during prediction: {str(e)}. Check model inputs and setup."
        )


# Run using 
# source C:/Users/Mocca/anaconda3/etc/profile.d/conda.sh
# conda activate adl_project
# uvicorn rest_api:app --reload
# curl http://127.0.0.1:8000/
# curl -X POST "http://127.0.0.1:8000/predict" \
# -H "Content-Type: application/json" \
# -d '{"document": "Wasps have announced the appointment of Lee Blackett as their new backs coach for next season. The 32-year-old will move to the Aviva Premiership side from Championship club Rotherham, where he is currently head coach. He will replace former Wales fly-half Stephen Jones, who is returning to the Llanelli-based Scarlets in a coaching capacity. Wasps have announced the appointment of Lee Blackett as their new backs coach for next season . Wasps rugby director Dai Young said: We always knew the time would come when Stephen would want to return to Wales with his young family. He has done a great job for us. Lee is one of the brightest young coaches in Britain, who has won admiration throughout the game for how he has turned Rotherham Titans into one of the strongest teams outside of the Premiership. He has impressed knowledgeable onlookers by his attention to detail, enthusiasm and professionalism, and his proven ability to get the best out of the players he coaches. Blackett (left) pictured playing for Leeds in 2010 as he is tackled by Guillaume Bousses (centre)","summary": "Lee Blackett will move to the English Super League side next season. The 42-year-old is currently CEO at Premier League football club Manchester City. Blackett will replace former England captain David Beckham."}'

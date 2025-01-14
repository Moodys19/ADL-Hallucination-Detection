from together import Together #type: ignore
import sys
import os
import time
import pandas as pd

# Specify the path to the directory containing get_api_key
external_module_path = "C:/mahmoud uni/TU/WS2024_2025/ADL"
sys.path.append(external_module_path)

# Import the get_api_key function
from get_api_key import get_api_key  # type: ignore

API_KEY = get_api_key()

def generate_chat_completion(
    model_name,
    messages,
    max_tokens=None,
    temperature=0.7,
    top_p=0.7,
    top_k=50,
    repetition_penalty=1,
    stop_sequences=None,
    stream=True
):
    """
    Generate chat completions using the Together API.

    Args:
        model_name (str): The name of the model to use.
        messages (list): A list of messages to provide as input.
        max_tokens (int or None): The maximum number of tokens to generate. Defaults to None.
        temperature (float): Sampling temperature. Defaults to 0.7.
        top_p (float): Nucleus sampling probability. Defaults to 0.7.
        top_k (int): Top-k sampling parameter. Defaults to 50.
        repetition_penalty (float): Penalty for repetition. Defaults to 1.
        stop_sequences (list or None): A list of stop sequences to halt generation. Defaults to None.
        stream (bool): Whether to stream the response. Defaults to True.

    Returns:
        Response object: The function returns the Together API response.
    """
    client = Together(api_key=API_KEY)

    if stop_sequences is None:
        stop_sequences = ["<|eot_id|>", "<|eom_id|>"]

    response = client.chat.completions.create(
        model=model_name,
        messages=messages,
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        top_k=top_k,
        repetition_penalty=repetition_penalty,
        stop=stop_sequences,
        stream=stream,
    )

    return response


def create_hallucinated_summaries(df, source_col, target_col, output_file_name, add_tokens = False):
    """
    Generate hallucinated summaries for each row of the DataFrame using an LLM and save them in a new column.
    
    Args:
        df (pd.DataFrame): The DataFrame containing the source and target text.
        source_col (str): The name of the column with the source text.
        target_col (str): The name of the column with the target summaries.
        output_col (str): The name of the column to save hallucinated summaries.
        output_file_name (str): path + name of the output file - the function saves 
                                the list automatically after each 250 lines 
    
    Returns:
        pd.DataFrame: The DataFrame with the new column containing hallucinated summaries.
    """

    # Validate the output_file_name
    output_dir = os.path.dirname(output_file_name)  # Extract directory from the path

    # If a directory is specified, check if it exists
    if output_dir and not os.path.exists(output_dir):
        raise ValueError(f"The directory '{output_dir}' does not exist. Please provide a valid path.")

    # Check if the output_file_name is writable
    if not output_file_name.endswith(".csv"):
        raise ValueError("The output file name must end with '.csv'.")

    print("path check")
    # Create an empty list to store the hallucinated summaries
    hallucinated_summaries = []

    # Define the system prompt

    if add_tokens:
        system_prompt = (
            "You are a creative summarization assistant. Your task is to create hallucinated summaries of text. "
            "For each given input summary, you should: "
            "1. Change only specific passages of the original text to hallucinated information while keeping the rest accurate. "
            "2. Ensure the length of the hallucinated summary matches the original summary exactly, with no additional or fewer words. "
            "3. Retain the structure, tone, and grammatical accuracy of the original summary. "
            "4. Only return the hallucinated summary as output, without any additional explanations or comments. "
            "5. Mark the hallucinated passages with special tokens: "
            "[B-hallucinated] before the hallucinated text and [E-hallucinated] after the hallucinated text."
            
            "\n\nExample: "
            "Original Summary: 'Harry Potter star Daniel Radcliffe gets £20M fortune as he turns 18 Monday. "
            "Young actor says he has no plans to fritter his cash away. Radcliffe's earnings from the first five Potter films have been held in a trust fund.' "
            "\nHallucinated Summary: 'Harry Potter star [B-hallucinated]loses fortune[E-hallucinated] as he turns 18 Monday. "
            "Young actor says he [B-hallucinated]has plans[E-hallucinated] to fritter his cash away. Radcliffe's earnings from the first five Potter films have been "
            "[B-hallucinated]spent entirely[E-hallucinated].' "
            "\n\nMake sure to hallucinate only parts of the summary while leaving some parts accurate."
            "Please make sure to mark everything correctly!"
            "Make sure to only return the hallucinated summary"
        )
    else:
        system_prompt =(
            "You are a creative summarization assistant. Your task is to generate hallucinated summaries of input text. A hallucinated summary alters specific details in the original text to include fabricated information while leaving other parts accurate."
            "For each input summary, follow these instructions:"
            "1. Change specific passages to hallucinated information while ensuring the rest of the text remains accurate."
            "2. Ensure the hallucinated summary is the exact same length as the original, with no additional or fewer words."
            "3. Retain the structure, tone, and grammatical accuracy of the original summary."
            "4. Avoid adding any meta-comments, such as 'Here is the hallucinated summary,' or any pretext. Provide only the hallucinated summary as output, with no explanations, comments, or pretext"
            "Example:"
            "Original Summary:"
            "'Harry Potter star Daniel Radcliffe gets £20M fortune as he turns 18 Monday. Young actor says he has no plans to fritter his cash away. Radcliffe's earnings from the first five Potter films have been held in a trust fund.'"
            "Hallucinated Summary: "
            "'Harry Potter star loses fortune as he turns 18 Monday. Young actor says he has plans to fritter his cash away. Radcliffe's earnings from the first five Potter films have been spent entirely.'"
            "\n\n Make sure to:"
            "Hallucinate only parts of the summary while leaving some parts accurate."
            "Produce an output that feels natural and coherent."
            "Return only the hallucinated summary as output, without explanations or additional comments."
        )

    total_rows = len(df)
    rate_limit = 55  # Maximum allowed requests per minute
    time_per_request = 60 / rate_limit  # Time needed per request in seconds

    # Process each row of the DataFrame
    for index, row in df.iterrows():

        start_time = time.time()  # Record the start time of the request
        print(f"Processing {index + 1}/{total_rows} rows...", end="\r")
        
        # Prepare the input messages for the LLM
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Source: {row[source_col]}\nSummary: {row[target_col]}"}
        ]

        # Call the LLM to generate the hallucinated summary
        response = generate_chat_completion(
            model_name="meta-llama/Llama-Vision-Free",
            messages=messages,
            max_tokens= 500,  
            temperature=0.5, # Allow room for hallucination
            top_p=0.9,
            top_k=40,
            repetition_penalty=1.2,
            stop_sequences=["<|eot_id|>", "<|eom_id|>"],
            stream=False
        )

        # Extract the hallucinated summary from the response
        hallucinated_summary = response.choices[0].message.content if response.choices else "Error: No response"

        # Save the hallucinated summary in the output column
        #df.at[index, output_col] = hallucinated_summary
        # Append the hallucinated summary to the list
        hallucinated_summaries.append(hallucinated_summary)

        # Calculate the time taken for the request
        elapsed_time = time.time() - start_time

        if (index + 1) % 250 == 0 or (index + 1) == total_rows:  # Also save at the last row
            # This was added after creating the fake summaries in create_fake_summaries.ipynb (15.12)
            output = pd.DataFrame(hallucinated_summaries, columns=["fake_summary"])
            output.to_csv(output_file_name, index=False, encoding="utf-8")
            print(f"\nProgress saved to {output_file_name} after {index + 1} rows.")

        # Sleep for the remaining time if necessary
        if elapsed_time < time_per_request:
            time.sleep(time_per_request - elapsed_time)

    print("\nProcessing complete!")
    return hallucinated_summaries
    #return df

import os
import pandas as pd
import numpy as np

def load_first_n_rows(n, file_paths):
    """
    Select the first n rows from src and tgt files for train, test, and valid datasets.

    Args:
        n (int): Number of rows to select.
        file_paths (dict): Dictionary containing file paths for train, test, and valid datasets.
            Example:
            {
                "train": {"src": "cnndm/train.src", "tgt": "cnndm/train.tgt"},
                "test": {"src": "cnndm/test.src", "tgt": "cnndm/test.tgt"},
                "valid": {"src": "cnndm/valid.src", "tgt": "cnndm/valid.tgt"}
            }

    Returns:
        dict: A dictionary containing DataFrames for train, test, and valid datasets.
    """
    datasets = {}

    # Create the subsamples directory if it doesn't exist
    subsamples_dir = "cnndm/subsamples"
    os.makedirs(subsamples_dir, exist_ok=True)

    for key, paths in file_paths.items():
        # Define output file paths
        src_output_path = os.path.join(subsamples_dir, f"{key}_src_{n}.src")
        tgt_output_path = os.path.join(subsamples_dir, f"{key}_tgt_{n}.tgt")

        # Check if files already exist
        if os.path.exists(src_output_path) and os.path.exists(tgt_output_path):
            print(f"Subsample files for {key} with {n} rows already exist. Loading them.")

            # Load existing files into DataFrame
            with open(src_output_path, "r", encoding="utf-8") as src_file:
                src_lines = src_file.readlines()

            with open(tgt_output_path, "r", encoding="utf-8") as tgt_file:
                tgt_lines = tgt_file.readlines()

            datasets[key] = pd.DataFrame({"source": [line.strip() for line in src_lines],
                                          "target": [line.strip() for line in tgt_lines]})
        else:
            # Read the first n lines from each file
            src_lines = []
            tgt_lines = []

            with open(paths['src'], "r", encoding="utf-8") as src_file:
                src_lines = [next(src_file).strip() for _ in range(n)]

            with open(paths['tgt'], "r", encoding="utf-8") as tgt_file:
                tgt_lines = [next(tgt_file).strip() for _ in range(n)]

            # Create a DataFrame
            datasets[key] = pd.DataFrame({"source": src_lines, "target": tgt_lines})

            # Save the resulting src and tgt files in the subsamples directory
            with open(src_output_path, "w", encoding="utf-8") as src_output_file:
                src_output_file.write("\n".join(src_lines) + "\n")

            with open(tgt_output_path, "w", encoding="utf-8") as tgt_output_file:
                tgt_output_file.write("\n".join(tgt_lines) + "\n")

    return datasets
import os
import pandas as pd

def load_n_rows(n, file_paths, start = 0):
    """
    Select the first n rows from train, test, and valid datasets stored in CSV files.

    Args:
        n (int): Number of rows to select.
        file_paths (dict): Dictionary containing file paths for train, test, and valid datasets.
            Example:
            {
                "train": "cnndm/train_raw.csv",
                "test": "cnndm/test_raw.csv",
                "valid": "cnndm/valid_raw.csv"
            }

    Returns:
        dict: A dictionary containing DataFrames for train, test, and valid datasets.
    """
    datasets = {}

    # Create the subsamples directory if it doesn't exist
    subsamples_dir = "cnndm/subsamples"
    os.makedirs(subsamples_dir, exist_ok=True)

    for key, file_path in file_paths.items():
        # Define output file path
        subset_output_path = os.path.join(subsamples_dir, f"{key}_subset_{n}.csv")

        # Check if the subset file already exists
        if os.path.exists(subset_output_path):
            print(f"Subset file for {key} with {n} rows already exists. Loading it.")
            
            # Load the existing subset CSV into a DataFrame
            datasets[key] = pd.read_csv(subset_output_path, sep=";")
        else:
            print(f"Creating subset file for {key} with {n} rows.")

            # Load the CSV and select the first n rows
            df = pd.read_csv(file_path, sep = ";")
            subset_df = df.iloc[start:n]

            # Save the subset to a new CSV file
            subset_df.to_csv(subset_output_path, index=False, sep= ";")

            # Add to the datasets dictionary
            datasets[key] = subset_df

    return datasets

# Example usage
file_paths_test_val = {
    "train": "cnndm/train_raw.csv",
    "test": "cnndm/test_raw.csv",
    "valid": "cnndm/valid_raw.csv"
}
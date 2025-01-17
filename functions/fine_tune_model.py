# Tokenize and calculate token lengths
def calculate_lengths(data, tokenizer, column_name):
    lengths = []
    for text in data[column_name]:
        tokens = tokenizer.tokenize(text)
        lengths.append(len(tokens))
    return lengths




# Calculate token lengths for each dataset
def filter_rows_by_length(dataset, tokenizer, max_length=512):
    """
    Filters rows where the combined token length of article and summary <= max_length.

    Args:
        dataset (pd.DataFrame): The dataset to filter.
        tokenizer (Tokenizer): The tokenizer for tokenization.
        max_length (int): The maximum combined token length.

    Returns:
        pd.DataFrame: Filtered dataset.
    """
    doc_lengths = calculate_lengths(dataset, tokenizer, "article")
    summ_lengths = calculate_lengths(dataset, tokenizer, "highlights")
    combined_lengths = [d + s + 3 for d, s in zip(doc_lengths, summ_lengths)]  # +3 for special tokens
    return dataset[[length <= max_length for length in combined_lengths]]


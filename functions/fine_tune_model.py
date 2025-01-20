import torch

# Tokenize and calculate token lengths
def calculate_lengths(data, tokenizer, column_name):
    """
    Calculates the token lengths for each text in the specified column of a dataset.

    Args:
        data (pd.DataFrame): The dataset containing the text data.
        tokenizer (Tokenizer): The tokenizer to tokenize the text.
        column_name (str): The name of the column in the dataset containing the text to tokenize.

    Returns:
        list: A list of integers representing the token lengths for each text entry.
    """
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



# Training function
def train_epoch(model, data_loader, optimizer, criterion, device):
    """
    Executes a single training epoch for the given model.

    Args:
        model (torch.nn.Module): The PyTorch model to be trained.
        data_loader (DataLoader): DataLoader providing batches of input data.
        optimizer (torch.optim.Optimizer): Optimizer to update model parameters.
        criterion (torch.nn.Module): Loss function to compute the error.
        device (torch.device): Device ('cpu' or 'cuda') where computations are performed.

    Returns:
        tuple: 
            - (float) Accuracy for the epoch (correct predictions / total samples).
            - (float) Average loss for the epoch.
    """

    model.train()
    losses = []
    correct_predictions = 0

    for batch_idx, batch in enumerate(data_loader):
        # Access the current batch index
        print(f"Processing batch {batch_idx + 1}/{len(data_loader)}", end = '\r')

        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['label'].to(device)

        outputs = model(input_ids=input_ids, attention_mask=attention_mask)
        logits = outputs.logits
        loss = criterion(logits, labels)
        losses.append(loss.item())

        _, preds = torch.max(logits, dim=1)
        correct_predictions += torch.sum(preds == labels)

        loss.backward()
        optimizer.step()
        optimizer.zero_grad()

    return correct_predictions.double() / len(data_loader.dataset), sum(losses) / len(losses)

def eval_model(model, data_loader, criterion, device):
    """
    Evaluates the performance of the given model on a dataset.

    Args:
        model (torch.nn.Module): The PyTorch model to evaluate.
        data_loader (DataLoader): DataLoader providing batches of input data for evaluation.
        criterion (torch.nn.Module): Loss function to compute the error.
        device (torch.device): Device ('cpu' or 'cuda') where computations are performed.

    Returns:
        tuple: 
            - (float) Accuracy of the model (correct predictions / total samples).
            - (float) Average loss over the dataset.
    """

    model.eval()
    losses = []
    correct_predictions = 0

    with torch.no_grad():
        for batch in data_loader:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['label'].to(device)

            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            logits = outputs.logits
            loss = criterion(logits, labels)
            losses.append(loss.item())

            _, preds = torch.max(logits, dim=1)
            correct_predictions += torch.sum(preds == labels)

    return correct_predictions.double() / len(data_loader.dataset), sum(losses) / len(losses)

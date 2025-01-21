import torch
from transformers import BertTokenizer, BertForSequenceClassification, AdamW

def load_model():
    """
    Loads the pre-trained BERT model, tokenizer and fine-tuned weights for sequence classification.

    Returns:
        tuple:
            - BertForSequenceClassification: The fine-tuned BERT model.
            - BertTokenizer: The tokenizer for text preprocessing.
    """

    tokenizer = BertTokenizer.from_pretrained("prajjwal1/bert-tiny")
    model = BertForSequenceClassification.from_pretrained("prajjwal1/bert-tiny", num_labels=2)
    model.load_state_dict(torch.load('models/best_model_state.bin', weights_only=True))
    model.eval()

    return model, tokenizer


def prepare_input(doc, summ, tokenizer, max_length=512):
    """
    Tokenize input tensors using the chunking logic applied in the training.

    Args:
        doc (str): The document text to encode.
        summ (str): The summary text to encode.
        tokenizer (Tokenizer): The tokenizer for tokenizing and encoding text.
        max_length (int): Maximum sequence length (default: 512).

    Returns:
        dict: A dictionary containing:
            - 'input_ids' (torch.Tensor): Encoded token IDs with padding.
            - 'attention_mask' (torch.Tensor): Mask indicating real tokens (1) vs. padding (0).
    """


    doc_tokens = tokenizer.tokenize(doc)
    summ_tokens = tokenizer.tokenize(summ)

    combined_tokens = (
        [tokenizer.cls_token_id] +
        tokenizer.convert_tokens_to_ids(doc_tokens) +
        [tokenizer.sep_token_id] +
        tokenizer.convert_tokens_to_ids(summ_tokens) +
        [tokenizer.sep_token_id]
    )
    
    if len(combined_tokens) > max_length:
        combined_tokens = combined_tokens[:max_length]
    
    attention_mask = [1] * len(combined_tokens)
    
    pad_length = max_length - len(combined_tokens)
    if pad_length > 0:
        combined_tokens += [tokenizer.pad_token_id] * pad_length
        attention_mask += [0] * pad_length
    
    return {
        "input_ids": torch.tensor([combined_tokens], dtype=torch.long),
        "attention_mask": torch.tensor([attention_mask], dtype=torch.long)
    }


def predict(text, summary, model, tokenizer):
    """
    Generate class prediction and probability distribution for a given document-summary pair.

    Args:
        text (str): The input document text.
        summary (str): The corresponding summary text.
        model (torch.nn.Module): The fine-tuned BERT model for sequence classification.
        tokenizer (Tokenizer): The tokenizer for text preprocessing and encoding.

    Returns:
        tuple:
            - (int): Predicted class (e.g., 0 or 1).
            - (torch.Tensor): Probabilities of each class as a tensor of shape [1, num_classes].
    """

    inputs = prepare_input(text, summary, tokenizer, max_length=512)
    input_ids = inputs["input_ids"]
    attention_mask = inputs["attention_mask"]

    with torch.no_grad():
        outputs = model(input_ids=input_ids, attention_mask=attention_mask)
        logits = outputs.logits
        probabilities = torch.softmax(logits, dim=1)
        prediction = torch.argmax(probabilities, dim=1).item()

    print(f"Prediction: {prediction}")
    print(f"Probabilities: {probabilities}")

    return prediction, probabilities

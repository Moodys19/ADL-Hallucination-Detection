# TODOs


- Vielleicht Kapitel mit dem R file auch
- welche ERROR METRIC
---
# Assignment 2 - Hacking

## Setup & gitignore
The following files and folders are included in the `.gitignore` file due to their large size or sensitive nature:

- **`cnndm/`**: This folder is used for storing data, including intermediate and cleaned files.  
- **`models/`**: This folder is used to store trained models.  
- **`get_api_key.py`**: This file contains the API key used for the LLM in the **Gathering the Data**  Chapter and looks as follows:


```python
def get_api_key():
    key = "ENTER API HERE"
    return(key)
```
Of course I have all the data and models available, if you need them please contact me!

The libraries needed for running the code can be found in the `requirements.txt`. For this project Python 3.10.15 was used.

## Baseline and Project Definition

In order to implement the proposal from Assignment 1, the project was divided into three subprojects:

- **Baseline**: The baseline project focuses on document-level classification, where the model takes a source text and its corresponding summary as input and predicts whether the summary contains any hallucinations or not.

- **Extension**: This stage extends the baseline by refining the classification from document-level to token-level classification.

- **Advanced Stage**: The goal here is to integrate **Semantic Entropy Probes (SEPs)**, as discussed in Assignment 1, into the model to enhance its performance and interpretability.

For Assignment 2, the primary focus was on implementing the data setup and cleaning pipeline, as well as developing the **Baseline** subproject.


## Gathering the Data

### Initial Data Overview

As mentioned in Assignment 1, the data used for this project is the [CNN/Daily Mail (CNNDM) dataset](https://huggingface.co/datasets/abisee/cnn_dailymail) (same dataset, different source), which contains news articles and their corresponding summaries. The dataset is pre-split into **Training**, **Test**, and **Validation** files, and was accessed using the Hugging Face `datasets` package.  

An initial data inspection conducted in `initial_data_overview.ipynb` confirmed that there are no missing values. The dataset contains:  
- **287,113** training articles and summaries 
- **11,490** test articles and summaries
- **13,368** validation articles and summaries

### Generating the Hallucinated Data
For the generation of the hallucinated summary, a Large Language Model (LLM) was used. [together.ai's Free Llama 3.2 11B Vision Model](https://www.together.ai/blog/llama-3-2-vision-stack) was chosen, as it provided a free API with up to 60 requests per minute (RPM). While more advanced APIs, such as Google's Gemini and OpenAI's models, are available, I opted against them due to limited prior experience. Additional experimentation would have been required, and the associated pay-as-you-go tariffs could have become costly. A [price estimation](https://yourgpt.ai/tools/openai-and-other-llm-api-pricing-calculator) was conducted after some testing.  

The hallucinated summary generation is implemented in `functions/call_llama.py` and `create_fake_summaries.ipynb`. Due to time constraints and the cap of 60 RPM, a subset of 7000 training articles and 1000 test and validation articles each was chosen. . 
These subsets were processed by prompting the LLM with the system prompt defined in `call_llama.py` and the chosen articles with their corresponding summaries.


## Data Quality
For this experiment ensuring high data quality is critical, as data contaminated with inconsistencies and artifacts can lead to a model that perfectly predicts the labels by learning the artifacts created through contaminated data, i.e. data containing artifacts resulting from the deliberate generation of hallucinations (see chapter **Baseline Model**). For this reason, considerable effort was devoted to cleaning and validating the generated data.

## Data Quality
Ensuring high data quality is critical for this experiment, as inconsistencies and artifacts in the data can lead to models that learn to predict labels based on these artifacts rather than the actual features. This is particularly relevant for data containing artifacts resulting from the deliberate generation of hallucinations (see chapter **Baseline Model**). For this reason, considerable effort was devoted to cleaning and validating the generated data.

### Data Cleaning
To generate hallucinated summaries, I experimented with various system prompts to obtain cleaner outputs. Despite these efforts, the LLM often produced artifacts, requiring both substantial manual and programmatic cleaning. The cleaning process was implemented in the script **`clean_data.R`** and addressed the following key issues:

- **Added Information**:  
   The model sometimes deviated from instructions in the system prompt by adding irrelevant prefixes or explanations, such as:  
   - "Here is a generated fake summary:"  
   - "However, I made the following summary."  

- **Sensitive Topics and Refusals**:  
   For sensitive topics, such as violence against children, the model occasionally refused to generate outputs. Such entries were removed from the dataset to ensure consistency and avoid gaps in the training data.

- **Token Artifacts**:  
    The LLM was instructed to include special hallucination tokens `[B-hallucinated]` and `[E-hallucinated]` for use in the token-level classification. Unfortunately, this task proved to be the biggest challenge as the LLM frequently (ironically) hallucinated tokens and generall seemed to have issues implementing said tokens:  
   - Excessive typos and hallucinated variations of tokens (e.g., "bhallucianted," "Ehallucination," "K-hallucination," "E[hallucaionation]")  
   - Misplaced or unmatched brackets  
   - Redundant spaces and inconsistent capitalization  


These errors affected more than half the entries. The primary challenge was that the errors were not uniform; they were often similar yet unique, making it difficult to correct them purely programmatically. The script applied regex-based transformations to standardize and clean the tokens wherever possible, ensuring that no token-related artifacts remained in the cleaned dataset. To implement, validate and monitor the cleanse, most of the data was manually inspected. Despite the considerable time invested in addressing the inconsistencies and artifacts, the results presented in the **Baseline Model** chapter indicate that further cleaning is required to ensure the removal of all artifacts and inconsistencies.  

After cleaning, the dataset was restructured, labels were added and the final outputs for training, test, and validation splits were saved into:  
- `train_data_base.csv`  
- `test_data_base.csv`  
- `valid_data_base.csv`  


## Baseline Model

The goal of the baseline model is to predict on document-level whether a summary contains hallucinations by fine-tuning a transformer-based model. This was achieved using the articles, summaries, and corresponding labels (hallucinated or not). The chosen Error Metric was a validation accuracy of around 0.7. This metric is a result of a lack of experience with such models, as well as the knowledge that the data quality could potentially not be sufficient for a strong model.

### Challenges

#### 1. Sequence Length  
One of the main challenges was handling the sequence length of the inputs. The **CNN/Daily Mail dataset** consists of long news articles paired with their summaries. Standard transformer models, such as BERT or BERT-tiny, can only process sequences up to a fixed number of 512 tokens  tokens - which would result in a large proportion of the observations being truncated, making the dataset unusable.


To ensure that both the articles and their summaries were included without losing critical information, I implemented the following strategies:  
- Tokenizing the article and summary together using **BERT's tokenizer**.
- Truncating sequences when they exceeded the maximum token limit.  
- Prioritizing the inclusion of as much of the summary as possible to preserve information relevant to hallucination classification.  

Despite these efforts, truncation led to the loss of some information, which may impact model performance.

---

#### 2. Model Size and Computational Constraints  
The original model I attempted to use was a standard **BERT-base** model. However, when running on **Google Colab**, the available RAM was insufficient to handle both the model size and the long sequences from the dataset. This issue resulted in out-of-memory (OOM) errors during training.  

To address this, I took the following steps:  
- Switched to **BERT-tiny**, a much smaller variant of BERT, to fit within the computational limits.  
- Reduced the **sequence length** to further minimize resource requirements.  

While these changes allowed the model to run, they introduced trade-offs:  
- The smaller model architecture reduces capacity to learn complex patterns in the data.  
- Reducing sequence length sacrifices observations by truncating input, further limiting model performance.  

As a result, this implementation serves as a **proof of concept** rather than a fully optimized model.

---

#### 3. Data Artifacts and Overfitting  
The results obtained from the baseline model were unexpectedly high, suggesting that the model might have exploited artifacts in the data rather than learning meaningful patterns. These artifacts are likely remnants from the hallucinated summary generation process and cleaning pipeline. Examples include:  
- Leftover tokens or patterns not fully removed during cleaning.  
- Irregularities in the fake summaries that the model can detect as "shortcuts" to classify hallucinated data.  

This highlights the importance of further improving the data cleaning process, as discussed in the **Data Quality** chapter. Ensuring that no artifacts remain is crucial for building a model that generalizes well and truly captures the underlying task.

---

### Conclusion  
The baseline model demonstrates the feasibility of fine-tuning transformers for hallucination detection. However, the challenges of sequence length, computational constraints, and lingering data artifacts significantly impacted the approach. While the current results are promising, they are not fully reliable, and further work is needed to optimize both the model and data preprocessing pipeline.


## Outlook


TODO: was würde ich besser machen Kapitel:
    - größeres BERT
    - Mehr trainingsdaten
    - genauer schauen

More sophisticated approach to cleaning the data
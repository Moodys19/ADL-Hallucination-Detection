# Assignment 3 - Deliver

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

## Continued Development and Refinement
As outlined in the "Outlook" chapter of my previous submission, further experimentation was undertaken to enhance data quality and achieve better results. To address the issue of "data contamination" caused by the LLM's difficulties in generating accurate tokens, the approach was revised. Instead of creating a single set of fake summaries for all subprojects, the focus was shifted exclusively to the baseline project. The model was instructed not to generate tokens but to focus solely on producing hallucinated summaries. This adjustment, paired with a reduced temperature setting, a more concise system prompt, and a stricter data-cleaning (including more aggressive removal of unfeasible rows), has led to a significant improvement in data quality.

In addition to data contamination, sequence length presented a significant challenge. The constraint of a maximum sequence length of 512—necessitated by the use of [BERT-Tiny](https://huggingface.co/prajjwal1/bert-tiny) due to computational limitations—resulted in approximately 70% of the data across training, testing, and validation being unsuitable for tokenization. As a result, this data was excluded from both training and evaluation, leading to a less robust model that struggled to produce meaningful inferences.
To address this limitation, a new subset of the [CNN/Daily Mail (CNNDM) dataset](https://huggingface.co/datasets/abisee/cnn_dailymail) was utilized. Similar to the subset used in Assignment 2, this dataset comprised 7,000 observations for training and 1,000 each for testing and validation. This selection ensured that the combined length of each article and its corresponding summary remained within the 512-token limit. As a result, approximately 99.5% of the selected data could be effectively utilized, enabling more robust model training and evaluation.

<div style="display: flex; justify-content: space-between; align-items: center;">
  <figure style="text-align: center; width: 45%;">
    <img src="Assignment Readmes\token_length_overview.png" alt="Image 1" style="width: 100%;">
    <figcaption>Token Length Distribution for Assignment 2 Data</figcaption>
  </figure>
  <figure style="text-align: center; width: 45%;">
    <img src="Assignment Readmes\token_length_overview_limited.png" alt="Image 2" style="width: 100%;">
    <figcaption>Token Length Distribution after Restriction</figcaption>
  </figure>
</div>


The number of epochs used for training remained unchanged at 20, with an early stopping mechanism triggered after 5 consecutive epochs without improvement. While the model took longer to converge in this iteration (11 epochs compared to 7 in Assignment 2), the overall results remained similar. However, inference yielded noticeably better outcomes, as initial inference experiments with the previous model always resulted in a non-hallucination detection. A closer discussion of the results and inference can be found in the report [TODO HIER DAS FILE LINKEN VIELLEICHT].

Due to the tight time frame and the primary focus on document-level detection, only limited experimentation with token-level detection was possible. Implementing token-level detection, along with extending the approach to include SEPs, would require a highly detailed data cleansing process to address the challenges posed by the LLM in generating accurate tokens, as well as a more refined tokenization strategy. However, these steps were not feasible within the available time frame.

## Inference using REST API and Webapp 


## Time Log
| Task Description                                                       | Time Spent (hours) |
|------------------------------------------------------------------------|-------------------:|
| Experimentation with system prompt and temperature parameter           | 1.5                |
| Superficial token-level detection experimentation (and data cleaning)  | 1                  |
| Resample, clean, and run new document-level detection approach         | 3 (+ 14 runtime for fake summary creation) |
| Research and implement web app                                         | X                  |
| Research and implement REST API                                        | X                  |
| Documentation, report, and presentation preparation                    | X                  |
| Video: finding the courage, filming, and editing                       | X                  |


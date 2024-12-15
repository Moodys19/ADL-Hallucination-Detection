# TODOs

- Im README die folder structure außerhalb des github ordners definieren
- Requirements file - Vielleicht Kapitel mit dem R file auch
- welche ERROR METRIC
    - auc
---
# Assignment 2 - Hacking
## Baseline and Project Definition
For the implementation of my proposal from assignment 1, the project was split into three branches:

- Baseline: The baseline project represents a document level classification, which takes a source text as well as a summary and predicts whether the summary is hallucinated or not (+ confidence score).

- Extension: Here we extend the baseline such that the classification from document level to token level classification.

- Advanced Stage: Here the aim is to integrate the Semantic Entropy Probes (SEPs) - discussed in Assignment 1 - into the model.

## Gathering the Data
### Initial Data Overview
As mentioned in Assignment 1 the data used for this project is the [CNN/Daily Mail (CNNDM) dataset](https://huggingface.co/datasets/RUCAIBox/Summarization/blob/main/cnndm.tgz), which contains news articles and corresponding summaries. The articles are already split into Training, Test and Validation files, with the articles being stored in the .src files, while the summaries are stored in the .tgt files. The initial data overview conducted in `initial_data_overview.ipynb` shows that there are no missing values. The original data contains 287 227 training articles, 11 490 test articles and 13 368 validation articles. 

### Generating the Hallucinated Data
For the generation of the hallucinated summary an LLM was used. Between finding the right model and the first experiments with it, most of the time of this submission was spent. Finally, 
[together.ai's Free Llama 3.2 11B Vision Model](https://www.together.ai/blog/llama-3-2-vision-stack) was chosen, as it provided a free API with up to 60 requests per minute (RPM). Both Google's Gemini and OpenAI offer APIs for better models, but I decided against them due to the lack of experience and the resulting need for more experimentation, as the pay-as-you-go tariffs need could potentially have been too expensive. The generation is done in `functions/call_llama.py` and `create_fake_summaries.ipynb`. Due to the tight time frame, a subset of 7000 training articles and 1000 test and validation articles each was chosen. These were created by prompting the LLM with the system prompt in `call_llama.py` as well as the chosen subsets of articles and summaries. 

#### Data Quality 
To ensure the quality of the data, I have manually addressed clear inconsistencies in the generated summaries. While this process is highly time-consuming, it is essential to maintain data integrity, as errors from the LLAMA model generating the fake summaries can significantly impact overall data quality and degrade the downstream model's performance. For instance, inconsistencies can arise when the model - against the instructions in the system prompt - outputs additional text such as "Here is a generated fake summary," instead of only producing the hallucinated summary. Additionally, for sensitive topics like violence against children, the model may refuse to generate a summary altogether, in such cases I chose to remove the entry. In a setting with a less tight time frame, I would spend even more time on this step to further investigate and control the types and quality of hallucinations. For this case random samples of the data were checked.
This analysis was implemented in the `clean_data.R`

TODO MACH DAS NOCH DETALLIERTER

TODO: hier issue mit den Tokens

## The Baseline Model


## Fine-Tuning the Bert-Model


## Folder Structure 
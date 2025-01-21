import streamlit as st
from functions.model_inference import load_model, predict

# 
@st.cache_resource 
def get_cached_model():
    return load_model()




def display_probability(probabilities):
    """
    Displays the hallucination probability as a progress bar and percentage using Streamlit.

    Args:
        probabilities (torch.Tensor): A tensor of shape [1, num_classes] containing the 
                                       predicted probabilities for each class.
    """

    hallucination_prob = probabilities[0, 1].item() # Extract hallucination probability
    st.write(f"Hallucination Probability: {hallucination_prob * 100:.2f}%")
    st.progress(hallucination_prob)

if __name__ == "__main__":    
    # Streamlit app UI
    st.header("Document-Level Hallucination Detection")
    st.write("This application estimates the probability that a summary contains hallucinations based on the corresponding article.")


    model, tokenizer = get_cached_model()
    article = st.text_area("Input Article", "", height=300)
    summary = st.text_area("Input Summary", "", height=150)

    if st.button("Check for Hallucinations"):
        if not article or not summary:
            st.error("Both article and summary are required.")
        else:
            with st.spinner("Analyzing..."):
                prediction, probabilities = predict(article, summary, model, tokenizer)

            if prediction == 0:
                st.success("The summary appears to be consistent with the article.")
            else:
                st.warning("The summary may contain hallucinations.")

            display_probability(probabilities)


# Run using
# source C:/Users/Mocca/anaconda3/etc/profile.d/conda.sh
# conda activate adl_project
# streamlit run webapp.py
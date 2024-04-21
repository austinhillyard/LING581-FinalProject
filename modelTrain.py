from transformers import AutoTokenizer, DataCollatorWithPadding, AutoModelForSequenceClassification, TrainingArguments, Trainer
from datasets import load_dataset, Dataset, DatasetDict
from sklearn.model_selection import train_test_split
import evaluate
import numpy as np
import pandas as pd
import itertools

checkpoint = "distilbert/distilbert-base-uncased"

labels = [
    "Warhammer40k", "40kLore", "Warhammer", "ageofsigmar", "PrequelMemes",
    "lotrmemes", "politics", "Conservative", "democrats", "Republican",
    "gaming", "StarWars", "lotr", "retrogaming", "ProgrammerHumor", "CloneWarsMemes",
    "Funnymemes", "minipainting", "SteamDeck", "Steam", "linux", "windows", "Grimdank"
]

# Create label2id dictionary
label2id = {label: idx for idx, label in enumerate(set(labels))}

# Create id2label dictionary
id2label = {idx: label for label, idx in label2id.items()}


file_path = 'dataTest.csv'

df = pd.read_csv(file_path)

df['subreddit'] = df['subreddit'].replace(label2id)

new_df = df[['subreddit', 'content']]

new_df = new_df.head(10)

data_dict = {'text': new_df['content'].tolist(), 'label': new_df['subreddit'].tolist()}

reddit_dataset = Dataset.from_dict(data_dict)

tokenizer = AutoTokenizer.from_pretrained(checkpoint)

print("Max input length", tokenizer.model_max_length)

def preprocess_function(examples):
    return tokenizer(examples["text"], truncation=True, max_length=512, padding="max_length")

tokenized_reddit = reddit_dataset.map(preprocess_function, batched=True)

tokenized_reddit = tokenized_reddit.train_test_split(train_size=.8, test_size=.2, seed=42)

data_collator = DataCollatorWithPadding(tokenizer=tokenizer)

accuracy = evaluate.load("accuracy")

def compute_metrics(eval_pred):
    predictions, labels = eval_pred
    predictions = np.argmax(predictions, axis=1)
    return accuracy.compute(predictions=predictions, references=labels)

model = AutoModelForSequenceClassification.from_pretrained(checkpoint, num_labels=len(labels), id2label=id2label, label2id=label2id)

training_args = TrainingArguments(
    output_dir="my_awesome_model",
    learning_rate=2e-5,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=2,
    weight_decay=0.01,
    evaluation_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
    push_to_hub=False,
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_reddit["train"],
    eval_dataset=tokenized_reddit["test"],
    tokenizer=tokenizer,
    data_collator=data_collator,
    compute_metrics=compute_metrics,
)

trainer.train()
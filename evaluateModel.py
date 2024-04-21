from transformers import AutoTokenizer, DataCollatorWithPadding, AutoModelForSequenceClassification, TrainingArguments, Trainer
from torch.utils.data import DataLoader
import evaluate

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


model_path = "my_awesome_model/checkpoint-2/"
model = AutoModelForSequenceClassification.from_pretrained(model_path)

tokenizer = AutoTokenizer.from_pretrained(model_path)

# metric = evaluate.load("glue", "mrpc")
# model.eval()

# eval_dataloader = DataLoader(
#     #tokenized_datasets["validation"], batch_size=8, collate_fn=data_collator
# )

input = "How on Horus did you write such small text?? Or was it a tiny decal moved into place? Cuz that is damn impressive!!"

data_collator = DataCollatorWithPadding(tokenizer=tokenizer)

tokens = data_collator.tokenizer(input)

output = model(tokens)

print(id2label(output))
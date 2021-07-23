'''
Author: jroberts, Nathan Bick, Chris Le
file: classify_words.py
'''

import spacy
from nltk.tokenize import word_tokenize
import pandas as pd

#reads the file into memory
with open("moby_dick_test.txt", "r") as f:
    file = f.read()

#loads an english language model
sp = spacy.load('en_core_web_sm')

#adds more words to the stop words repo to limit the amount "non-crtitcal" words
#feel free to add more that you seem "non-critical"
all_stopwords = sp.Defaults.stop_words
sp.Defaults.stop_words.add(",")
sp.Defaults.stop_words.add("I")
sp.Defaults.stop_words.add(".")
sp.Defaults.stop_words.add(";")
sp.Defaults.stop_words.add("--")
sp.Defaults.stop_words.add("?")
sp.Defaults.stop_words.add("!")
sp.Defaults.stop_words.add("''")
sp.Defaults.stop_words.add("``")
sp.Defaults.stop_words.add("A")
sp.Defaults.stop_words.add("O")
sp.Defaults.stop_words.add("oh")
sp.Defaults.stop_words.add("Oh")
sp.Defaults.stop_words.add("On")
sp.Defaults.stop_words.add("AND")
sp.Defaults.stop_words.add("AM")
sp.Defaults.stop_words.add("TO")
sp.Defaults.stop_words.add("So")
sp.Defaults.stop_words.add("The")
sp.Defaults.stop_words.add("Am")
sp.Defaults.stop_words.add("But")
sp.Defaults.stop_words.add("For")
sp.Defaults.stop_words.add("Ho")
sp.Defaults.stop_words.add("ho")
sp.Defaults.stop_words.add("ye")
sp.Defaults.stop_words.add("Ye")
sp.Defaults.stop_words.add("-")
sp.Defaults.stop_words.add("'")
sp.Defaults.stop_words.add("as")
sp.Defaults.stop_words.add("As")

#tokenizes by word the text file
text_tokens = word_tokenize(file)

#filters the stop words out
tokens_without_sw= [word for word in text_tokens if not word in all_stopwords]

#creates a string of words from a list
tokens = " ".join(tokens_without_sw)

#the language model will not take a list only a string
doc = sp(tokens)

#creates dictionary with word as the key and part of speech as the value
#now that I think about it we may want to switch this into part of speech as key and word as value
data = {}
for ent in doc:
    data[ent] = ent.pos_

dictionary = {"word": list(data.keys()), "part_of_speech": list(data.values())}
df = pd.DataFrame.from_dict(dictionary)

#you may need to switch the "9" in the sample method to get it to sample the number you want
grouped_df = df.groupby("part_of_speech", group_keys=False).apply(lambda x: x.sample(min(len(x), 9)))


#run this to generate a csv
#df.to_csv("moby_dick_test.csv")
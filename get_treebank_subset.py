import pandas

data = pandas.read_csv("ud-tts-ud-corpus.csv")
print(len(data))
data = data[data["num of sentences"]>10000]
print(len(data))
with open("treebank-list.txt", "w") as o:
    for i, row in data.iterrows():
        corpus = row["corpus"]
        if corpus == "KAIST":
            corpus = corpus.lower()
            corpus = corpus.capitalize()
        o.write("UD_"+row["UD Language"]+"-"+corpus)
        o.write("\n")

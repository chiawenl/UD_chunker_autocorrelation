def read_treebank(filepath, punct=True):
    tree, trees = [], []
    with open(filepath, "r") as f:
        for line in f:
            if line == "\n":
                if not punct:
                    tree = remove_punct(tree)
                trees.append(tree)
                tree = []
            elif line.startswith("#"):
                continue
            items = line.strip().split("\t")
            if "." in items[0] or "-" in items[0]:
                continue
            if len(items) != 10:
                continue
            node = [int(items[0])]
            node += items[1:]
            tree.append(node)
    return trees

def remove_punct(tree):
    i2j = {0: 0}
    nodes_to_ignore = []
    for node in tree:
        head_id = int(node[6])-1
        if head_id < 0:
            continue
        if tree[head_id][3] == "PUNCT":
            nodes_to_ignore.append(int(tree[head_id][0]))

    for node in tree:
        if node[3] == "PUNCT":
            if int(node[0]) not in nodes_to_ignore:
                continue
        i2j[node[0]] = len(i2j)
    tree_wo_punct = []
    for node in tree:
        if node[0] not in i2j.keys():
            continue
        new_id = i2j[node[0]]
        try:
            new_head_id = str(i2j[int(node[6])])
        except:
            print(nodes_to_ignore)
            print(node)
            print("--------------")
            for n in tree:
                print(n)
            exit()
        new_node = [new_id] + node[1:6] + [new_head_id] + node[7:]
        tree_wo_punct.append(new_node)
    for n in tree_wo_punct:
        if int(n[6]) > len(tree_wo_punct):
           exit("Messed up punctuation removal, " + n[6] + ", " + str(len(tree_wo_punct)))
    return tree_wo_punct

def save_as_conllxi(trees, outpath):
    with open(outpath, "w") as o:
        for tree in trees:
            for node in tree:
                o.write("\t".join([str(n) for n in node]))
                o.write("\n")
            o.write("\n")


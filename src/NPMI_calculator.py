import numpy as np

def get_joint_probabilities(trees, relations, tags):
    counts, t = get_joint_counts(trees, relations, tags)
    probabilities = {}
    alpha = 0.00
    n_contexts = len(counts.keys())
    for context, count in counts.items():
        p = (count + alpha) / (t + n_contexts * alpha)
        probabilities[context] = p
    return probabilities

def get_relations_and_tags(trees):
    relations = set([])
    tags = set([])
    for tree in trees:
        for node in tree:
            tags.add(node[3])
            if int(node[6]) == 0:
                continue
            relation = node[7].split(":")[0]
            relations.add(relation)
    return relations, tags

def get_tag_probabilities(trees, tags):
    counts = {tag: 0. for tag in tags}
    tokens = 0.
    alpha = 0.00
    for tree in trees:
        for node in tree:
            tag = node[3]
            counts[tag] += 1
            tokens += 1
    probabilities = {}
    for tag, count in counts.items():
        probabilities[tag] = (count + alpha) / (tokens + alpha * len(tags))
    return probabilities

def get_head_real_probabilities(trees, relations, tags):
    counts = {}
    for tag in tags:
        for rel in relations:
            counts[(tag, rel)] = 0.
    tokens = 0.
    alpha = 0.00
    for tree in trees:
        for node in tree:
            head_id = int(node[6])
            if head_id == 0:
                continue
            head_tag = tree[head_id-1][3]
            rel = node[7].split(":")[0]
            counts[(head_tag,rel)] += 1
            tokens += 1
    probabilities = {}
    n_pairs = len(counts.keys())
    for tag, count in counts.items():
        probabilities[tag] = count / tokens 
    return probabilities


def get_joint_counts(trees, relations, tags):
    counts = initialise_joint_counts(trees, relations, tags)
    t = 0.
    for tree in trees:
        for node in tree:
            head_id = int(node[6])
            if head_id == 0:
                continue
            head_pos = tree[head_id-1][3]
            relation = node[7].split(":")[0]
            context = (node[3], head_pos, relation)
            counts[context] += 1
            t += 1
    return counts, t

def initialise_joint_counts(trees, relations, tags):
    counts = {}
    for tag in tags:
        for rel in relations:
            for head in tags:
                counts[(tag, head, rel)] = 0.
    return counts

def get_np_mutual_information_values(trees):
    relations, tags = get_relations_and_tags(trees)
    joint_probabilities = get_joint_probabilities(trees, relations, tags)
    tag_probabilities = get_tag_probabilities(trees, tags)
    head_rel_probabilties = get_head_real_probabilities(trees, relations, tags)
    MI_values = {} 
    relations, tags = get_relations_and_tags(trees)
    for tag in tags:
        for head_pos in tags:
            for rel in relations:
                joint_p = joint_probabilities[(tag, head_pos, rel)]
                tag_p = tag_probabilities[tag]
                head_rel_p = head_rel_probabilties[(head_pos,rel)]
                if tag_p == 0 or joint_p == 0 or head_rel_p == 0:
                    mi = 0.
                else:
                    mi = (np.log(joint_p/ (tag_p * head_rel_p))) / (-np.log(joint_p))
                MI_values[(tag,head_pos,rel)] = mi
    return MI_values
                                                        







import os
from operator import itemgetter
import numpy as np

def get_chunk_NPMI(chunk, mi_values):
    mi_total = 0.
    root_id = get_chunk_root_id(chunk)
    for node in chunk:
        if node[0] == root_id:
            continue
        tag = node[3]
        head_tag = chunk[-1][3]
        rel = node[7].split(":")[0]
        context = (tag, head_tag, rel)
        try:
            mi_total += mi_values[context]
        except:
            mi_total -= 1.
    return mi_total / (len(chunk)-1)


def check_if_potential_chunk(node,  tree):
    node_id = int(node[0])-1
    head_id = int(node[6])-1
    if node_id < head_id:
        for n in tree[node_id:head_id]:
            if int(n[6])-1 != head_id:
                if int(n[6]) != 0:
                    return False
    elif node_id > head_id:
        for n in tree[head_id+1:node_id+1]:
            if int(n[6])-1 != head_id:
                if int(n[6]) != 0:
                    return False
    return True

def display_chunks(chunks):
    for c in chunks:
        print("----------------------")
        for n in c:
            print(n)

def sweep_up_unitary_chunks(chunks, tree, used_nodes):
    all_c_ids = [node[0] for c in chunks for node in c]
    unitaries = [node for node in tree if node[0] not in all_c_ids]
    updated_chunks = []
    attached = set([])
    for chunk in chunks:
        new_chunk = None
        c_ids = [n[0] for n in chunk]
        for u in unitaries:
            u_id = u[0]
            if u_id in attached:
                continue
            if min(c_ids) - u_id == 1:
                if unitary_is_related(u, chunk):
                    if new_chunk is not None:
                        new_chunk = [u] + new_chunk
                    else:
                        new_chunk = [u] + chunk
                    attached.add(u_id)
                
            elif u_id - max(c_ids) == 1:
                if unitary_is_related(u, chunk):
                    if new_chunk is not None:
                        new_chunk = new_chunk + [u]
                    else:
                        new_chunk = chunk + [u]
                    attached.add(u_id)
        if new_chunk is None:
            updated_chunks.append(chunk)
        else:
            updated_chunks.append(new_chunk)
    if check_chunks(updated_chunks, tree):
        return updated_chunks, used_nodes.union(attached)
    else:
        print("nodes in chunks:", len([n for c in updated_chunks for n in c]))
        print("nodes in tree:", len(tree))
        display_chunks(updated_chunks)
        exit("Problem attaching unitary nodes.")

def check_chunks(chunks, tree):
    nodes_in_chunks = len([n for c in chunks for n in c])
    if nodes_in_chunks > len(tree):
        return False
    return True
              
def unitary_is_related(unitary, chunk):
    return True
    c_ids  = [int(n[0]) for n in chunk]
    c_head_ids = [int(n[6]) for n in chunk]
    if int(unitary[0]) in c_head_ids:
        return True
    elif int(unitary[6]) in c_head_ids:
        return True
    elif unitary[3] == "PUNCT":
        return True
    else:
        return False
        
def annotate_trees_with_chunk_labels(trees, mi_values, threshold, sweep):
    tokens = 0.
    in_chunks = 0.
    chunk_n = 0.
    annotated_trees = []
    for tree in trees:
        potential_chunks = []
        n_id = 0
        tokens += len(tree)
        while n_id < len(tree)-1:
            node = tree[n_id]
            chunk = []
            n_id += 1
            if check_if_potential_chunk(node, tree):
                head_id = int(node[6])-1
                node_id = int(node[0])-1
                if node_id < head_id:
                    for n in tree[node_id:head_id+1]:
                        chunk.append(n)
                else:
                    for n in tree[head_id:node_id+1]:
                        chunk.append(n)
                if len(chunk) > 1:
                    npmi = get_chunk_NPMI(chunk, mi_values)
                    potential_chunks.append((chunk, npmi))
                    n_id = chunk[-1][0]

        potential_chunks = sorted(potential_chunks,
                                  key=itemgetter(1),
                                  reverse=True)

        chunks = []
        used_nodes = set([])
        for c, npmi in potential_chunks:
            ids = set(n[0] for n in c)
            if len(used_nodes.intersection(ids)) > 0:
                continue
            if npmi >= threshold:    
                chunks.append(c)
                chunk_n += 1
                for n in c:
                    in_chunks += 1
                    used_nodes.add(n[0])
        
        if sweep:
            chunks, used_nodes = sweep_up_unitary_chunks(chunks,
                                                         tree,
                                                         used_nodes)
        annotated_tree = annotate_tree(used_nodes, tree, chunks)
        if len(annotated_tree) != len(tree):
            print(len(annotated_tree), len(tree))
            for n in annotated_tree:
                print(n)
            exit("annotated tree as repeated nodes")
        annotated_trees.append(annotated_tree)
   

    return annotated_trees


def annotate_tree(used_nodes, tree, chunks):
    annotated_tree = []
    chunk_id = 0
    for node in tree:
        if node[0] not in used_nodes:
            node += ["O"]
            annotated_tree.append(node)
            continue
    for c in chunks:
        root_id = get_chunk_root_id(c)
        chunk_type = tree[root_id-1][3]
        for i, node in enumerate(c):
            if i == 0:
                prefix = "B"
            else:
                prefix = "I"
            node_id = int(node[0])
            if node_id == root_id:
                relation = "HEAD"
            else:
                relation = node[7].split(":")[0]
            ## edited out more detailed label as not needed here, I believe
            #chunk_label = prefix + "-" + chunk_type + "|" +  relation
            chunk_label = prefix            
            node.append(chunk_label)
            annotated_tree.append(node)
    annotated_tree = sorted(annotated_tree, key=itemgetter(0))
    return annotated_tree

def get_chunk_root_id(chunk):
    all_ids = [int(node[0]) for node in chunk]
    for node in chunk:
        if int(node[6]) < min(all_ids) or int(node[6]) > max(all_ids):
            return int(node[0])
    exit("Chunk is messed up")



def get_stats(annotated_trees, csv=False):
    lengths = get_chunk_lengths(annotated_trees)
    mu, std = get_mean_chunk_length(lengths)
    unitary_ratio = get_unitary_ratio(lengths)
    lengths_wo_punct = get_chunk_lengths(annotated_trees, punctuation=False)
    mu_wo_punct, std_wo_punct = get_mean_chunk_length(lengths_wo_punct)
    unitary_ratio_wo_punct = get_unitary_ratio(lengths_wo_punct)
    if not csv:
        print("\nAverage chunk length: " + format(mu, ".3f") + " (" + format(std, ".3f")+")")
        print("Unitary chunk proportion: " + format(unitary_ratio, ".3f"))
        print("\nAverage chunk length w/o unitary punct: " + format(mu_wo_punct, ".3f") + " (" + format(std_wo_punct, ".3f")+")")
        print("Unitary chunk proportion w/o unitary punct: " + format(unitary_ratio_wo_punct, ".3f"))
    else:
        out_vals = [mu,std,unitary_ratio,mu_wo_punct,std_wo_punct,unitary_ratio_wo_punct]
        out_vals_str = [str(v) for v in out_vals]
        print(",".join(out_vals_str))
    return lengths, lengths_wo_punct
    
def get_unitary_ratio(lengths):
    unitary_chunks = [l for l in lengths if l==1]
    return len(unitary_chunks) / len(lengths)
    
def get_chunk_lengths(annotated_trees, punctuation=True):
    chunks = []
    chunk = []
    for tree in annotated_trees:
        for node in tree:
            chunk_label = node[-1]
            if chunk_label.startswith("B"):
                if len(chunk) > 0:
                    chunks.append(chunk)
                chunk = [node]
            elif chunk_label.startswith("I"):
                chunk.append(node)
            elif chunk_label.startswith("O"):
                if len(chunk) > 0:
                    chunks.append(chunk)
                chunk = []
                if not punctuation and node[3] == "PUNCT":
                    continue
                chunks.append([node])
    lengths = [len(chunk) for chunk in chunks]
    return lengths

def get_mean_chunk_length(lengths):
    return np.mean(lengths), np.std(lengths)
    
def save_lengths(lengths, outfile):
    with open(outfile, "w") as o:
        for l in lengths:
            o.write(str(l))
            o.write("\n")
       

import random
import math
import argparse
import json
def get_layer(total, branch):
    tmp_sum = 0
    i = 0
    while(True):
        tmp_sum += branch ** i
        if tmp_sum >= total:
            return i + 1
        else:
            i += 1
class Tree:
    def __init__(self, shard_number, branch, is_full=False):
        self.branch = branch
        self.is_full = is_full
        self.total = shard_number
        self.layer = get_layer(self.total, self.branch)
        self.dist = [[1 for _ in range(self.total)] for _ in range(self.total)]
        for i in range(self.total):
            for j in range(self.total):
                self.dist[i][j] = random.randint(1, 10000)
                self.dist[j][i] = self.dist[i][j]
    # 获取从上往下第l层，从左往右第k个节点的子节点的位置，共branch个
        # 第l + 1层， 旁边有k - 1个节点的子节点，每个节点有branch个子节点
    def get_child_position(self, l, k):
        return [[l + 1, (k - 1) * self.branch + i + 1] for i in range(self.branch)]
    # 在满叉的情况下，首先建立一个层序遍历结果为1,2,3，……的满n叉树
        # 然后建立一个真实id到上述满n叉树上的结构id的映射
        # 真实id只要保证不重复不冲突即可，通过随机数生成和dict检测冲突
    def get_id_map(self):
        real2struct = {}
        struct2real = {}
        for i in range(1, self.total + 1):
            tmp = random.randint(1, self.total)
            while tmp == i or tmp in real2struct:
                tmp = random.randint(1, self.total)
            real2struct[tmp] = i
            struct2real[i] = tmp
        return real2struct, struct2real
    def check_full(self, edges, number):
        result = 0
        for edge in edges:
            if edge[0] == number:
                result += 1
        return result >= self.branch
    # prime算法
    def prime(self):
        visited = [False for i in range(self.total)]
        root = random.randint(0, self.total - 1)
        selected = [root]
        visited[root] = True
        edges = []
        for i in range(self.total - 1):
            minDist = 10000
            next_select = -1
            new_edge = []
            for j in range(self.total):
                if not visited[j]:
                    for k in selected:
                        # 防止超过n叉
                        if self.check_full(edges, k):
                            continue
                        if self.dist[j][k] < minDist:
                            minDist = self.dist[j][k]
                            next_select = j
                            new_edge = [k ,j]
            visited[next_select] = True
            selected.append(next_select)
            edges.append(new_edge)
        return edges, root
    def get_json(self):
        result = {}
        # 在满叉的情况下
        if self.is_full:
            # 首先获取真实id和结构id的双向映射
            real2struct, struct2real = self.get_id_map()
            result["root"] = str(struct2real[1])
            # 遍历所有非叶子节点的结构id，最终的json中只需要非叶子节点作为key
            for struct_id in range(1, self.total + 1 - self.branch ** (self.layer - 1)):
                # 节点的真实id
                real_id = struct2real[struct_id]
                # 获取结构id对应在树上的位置，从上往下第l层，从左往右第k个
                l = get_layer(struct_id, self.branch)
                tmp_sum = (self.branch ** l - 1) / (self.branch - 1)
                k = self.branch ** (l - 1) - (int(tmp_sum) - struct_id)
                # 获取所有子节点的位置
                child_position = self.get_child_position(l, k)
                child_str = ""
                # 遍历所有子节点
                for child in child_position:
                    # 根据位置计算得到子节点的结构id
                    child_struct_id = int((self.branch ** (child[0] - 1) - 1) / (self.branch - 1)) + child[1]
                    # 根据结构id得到子节点的真实id
                    child_real_id = struct2real[int(child_struct_id)]
                    child_str += "{},".format(child_real_id)
                result[real_id] = child_str[:-1]
        # 非满叉的情况
        else:
            # 先初始化一个所有顶点两两相连的无向图的邻接矩阵，邻接矩阵中(i,j)和(j,i)相同，为i,j之间的距离，随机
            edges, root = self.prime() # 通过prime算法得到这个图的最小生成树，由于所有边的权重是随机的，可以认为最后的结果也是随机的
            print(root)
            result = {}
            result["root"] = str(root + 1)
            for edge in edges:
                if edge[0] + 1 not in result:
                    result[edge[0] + 1] = "{},".format(edge[1] + 1)
                else:
                    result[edge[0] + 1] += "{},".format(edge[1] + 1)
            for key in result:
                if key != "root":
                    result[key] = result[key][:-1]
        return result
if __name__ == '__main__':
    parse = argparse.ArgumentParser()
    parse.add_argument('-n', type=int, default="13", help='分片总数')
    parse.add_argument('-b', type=int, default=3, help='叉数,每个父节点最多几个子节点')
    parse.add_argument('-f', action='store_true', default=False, help="是否满叉")
    opt = parse.parse_args()
    tree = Tree(opt.n, opt.b, opt.f)
    with open("tree.json", "w") as f:
        f.write(json.dumps(tree.get_json()))

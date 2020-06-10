import ballerina/io;
import ballerina/lang.'xml as xmllib;
import ballerina/stringutils;

# Prints `Hello World`.

public function main() {
    Tree|error t = new Tree("files/Main.xml");
    if (t is Tree) {
        t.print();
    }
}

public type CodeWriter object {
    private Node root;
    private string class = "";
    private string func = "";
    private Tree tree;
    public function __init(string file) returns error? {
        Tree|error tree = new (file);
        if (tree is error) {
            return tree;
        } else {
            self.tree = tree;
            self.root = tree.getRoot();
        }
    }
    public function getCode() returns string|boolean {
        return self.getCodeReq(self.root);
    }
    private function getCodeReq(Node node, Node? parent = ()) returns string|boolean {
        Node[] childeren = node.getChilderen();
        string code = "";

        if (node.getName() == "class") {
            self.class = childeren[1].getValue();
            childeren = childeren.slice(3, childeren.length() - 4);
            foreach var child in childeren {
                string|boolean res = self.getCodeReq(child, node);
                if (res is string) {
                    code += res;
                } else {
                    return false;
                }
            }
            self.tree.clearClassTable();
        }

        if (node.getName() == "classVarDec") {
            string decType = childeren[0].getValue();
            string decKind = childeren[1].getValue();
            boolean succ = self.tree.addRecord("class", childeren[2].getValue(), decType, decKind);
            if (!succ) {
                return false;
            }
            int index = 3;
            while (childeren[index].getValue() !== ";") {
                succ = self.tree.addRecord("class", childeren[index + 1].getValue(), decType, decKind);
                if (!succ) {
                    return false;
                }
                index += 2;
            }
        }

        if (node.getName() == "varDec") {
            string decType = childeren[0].getValue();
            string decKind = childeren[1].getValue();
            boolean succ = self.tree.addRecord("class", childeren[2].getValue(), decType, decKind);
            if (!succ) {
                return false;
            }
            int index = 3;
            while (childeren[index].getValue() !== ";") {
                succ = self.tree.addRecord("class", childeren[index + 1].getValue(), decType, decKind);
                if (!succ) {
                    return false;
                }
                index += 2;
            }
        }

        if (node.getName() == "subroutineDec") {
            self.tree.clearMethodTable();
            string returnType = "";
            string funcType = "";
            string funcName = "";
            if (childeren[0].getValue() == "method") {
                funcType = "method";
                returnType = childeren[1].getValue();
                funcName = childeren[2].getValue();
                _ = self.tree.addRecord("func", "this", self.class, "arg");
            }
            if (childeren[0].getValue() == "function") {
                funcType = "function";
                returnType = childeren[1].getValue();
                funcName = childeren[2].getValue();
            }
            if (childeren[0].getValue() == "constructor") {
                funcType = "constructor";
            }
            _ = self.getCodeReq(childeren[4], node);
            boolean|string res = self.getCodeReq(childeren[6], node);
            if (res is boolean) {
                return false;
            } else {
                code += res;
            }
        }

        if (node.getName() == "parameterList") {
            int index = 0;
            while (index + 1 < childeren.length()) {
                boolean succ = self.tree.addRecord("func", childeren[1].getValue(), childeren[0].getValue(), "arg");
                if (!succ) {
                    return false;
                }
                index += 3;
            }
        }

        if (node.getName() == "subroutineBody") {
            foreach var child in childeren {
                if (child.getName() == "varDec" || child.getName() == "statements") {
                    boolean|string res = self.getCodeReq(child, node);
                    if (res is boolean) {
                        return false;
                    } else {
                        code += res;
                    }
                }
            }
        }

        //TODO Code writing here
        return code;
    }
};

public type VarRec record {|
    string varType;
    string varKind;
    int number;
|};

public type Node object {
    private Node? parent = ();
    private Node[] childeren = [];
    private string value = "";
    private string name = "";
    private string row = "";
    private string col = "";


    public function __init(string name, string value = "", string row = "", string col = "") {
        self.name = name;
        self.value = value;
        self.row = row;
        self.col = col;
    }

    public function getName() returns string {
        return self.name;
    }

    public function getValue() returns string {
        return self.value;
    }

    public function isLeaf() returns boolean {
        return self.childeren.length() == 0;
    }

    public function getChilderen() returns Node[] {
        return self.childeren;
    }

    public function addChild(Node child) {
        child.setParent(self);
        self.childeren.push(child);
    }

    private function setParent(Node parent) {
        self.parent = parent;
    }
    private function getOffset(int num) returns string {
        string s = "";
        int n = num;
        while (n > 0) {
            s += "\t";
            n -= 1;
        }
        return s;
    }

    public function printXML() returns string {
        return self.printSubTree(0);
    }

    private function printSubTree(int depth) returns string {
        if (!self.isLeaf()) {
            string res = self.getOffset(depth) + "<" + self.name + ">\n";
            foreach var child in self.childeren {
                res += child.printSubTree(depth + 1);
            }
            res += self.getOffset(depth) + "</" + self.name + ">\n";
            return res;
        } else {
            string res = stringutils:replaceAll(self.value, "&", "&amp;");
            res = stringutils:replaceAll(res, "<", "&lt;");
            res = stringutils:replaceAll(res, ">", "&gt;");
            if (res == "") {
                res = "\n" + self.getOffset(depth);
            }
            if (self.row != "" || self.col != "") {
                return self.getOffset(depth) + "<" + self.name + " row=\"" + self.row + "\" col=\"" + self.col + "\" >" + res + "</" + self.name + ">\n";
            } else {
                return self.getOffset(depth) + "<" + self.name + ">" + res + "</" + self.name + ">\n";
            }
        }
    }
};


public type Tree object {
    private Node root;
    private map<VarRec> classVarTable = {};
    private map<VarRec> methodVarTable = {};
    private int localT = 0;
    private int argT = 0;
    private int fieldT = 0;
    private int staticT = 0;
    public function __init(string file) returns @tainted error? {
        self.root = new Node("class");
        xml|error treeFile = self.readXml(file);
        if (treeFile is error) {
            return treeFile;
        } else {
            self.buildTree(treeFile, self.root);
        }
    }
    public function getClassRecord(string name) returns VarRec? {
        return self.classVarTable[name];
    }
    public function getMethodRecord(string name) returns VarRec? {
        return self.methodVarTable[name];
    }
    public function clearClassTable() {
        self.classVarTable = {};
    }
    public function clearMethodTable() {
        self.methodVarTable = {};
    }
    public function addRecord(string fromTable, string name, string varType, string kind) returns boolean {
        int num = 0;
        match kind {
            "field" => {
                self.fieldT += 1;
                num = self.fieldT;
            }
            "static" => {
                self.staticT += 1;
                num = self.staticT;
            }
            "var" => {
                self.localT += 1;
                num = self.localT;
            }
            "let" => {
                self.localT += 1;
                num = self.localT;
            }
            "arg" => {
                self.argT += 1;
                num = self.argT;
            }
        }
        if (fromTable == "class") {
            if (self.classVarTable[name] is VarRec) {
                return false;
            } else {
                self.classVarTable[name] = {varType: varType, varKind: kind, number: num};
                return true;
            }
        } else {
            if (self.methodVarTable[name] is VarRec) {
                return false;
            } else {
                self.methodVarTable[name] = {varType: varType, varKind: kind, number: num};
                return true;
            }
        }
    }
    public function print() {
        io:println(self.root.printXML());
    }
    public function getRoot() returns Node {
        return self.root;
    }
    private function buildTree(xml treeFile, Node node) {
        xml eTreeFile = treeFile/<*>;
        eTreeFile.forEach(function(xml item) {
            xmllib:Element eItem = <xmllib:Element>item;
            xml childeren = item/<*>;
            Node child;
            if (childeren.length() > 1) {
                child = new Node(
                    eItem.getName().toString(),
                    "",
                    eItem.getAttributes()["row"].toString(),
                    eItem.getAttributes()["col"].toString());
            } else {
                child = new Node(
                    eItem.getName().toString(),
                    eItem.getChildren().toString(),
                    eItem.getAttributes()["row"].toString(),
                    eItem.getAttributes()["col"].toString());
            }
            node.addChild(child);
            self.buildTree(item, child);
        });
    }
    private function readXml(string path) returns @tainted xml|error {
        io:ReadableByteChannel rbc = check io:openReadableFile(path);
        io:ReadableCharacterChannel rch = new (rbc, "UTF8");
        var xmlResult = rch.readXml();
        var result = rch.close();
        if (result is error) {
            io:println("Error occurred while closing character stream");
        }
        return xmlResult;
    }
};


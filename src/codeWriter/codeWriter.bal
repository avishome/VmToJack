import ballerina/io;
import ballerina/lang.'xml as xmllib;
import ballerina/stringutils;

# Prints `Hello World`.

public function main() {
    io:println("Hello World!");
    Tree|error t = new Tree("files/Main.xml");
    if(t is Tree){
        t.print();
    }
}

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
    public function __init(string file) returns @tainted error? {
        self.root = new Node("class");
        xml|error treeFile = self.readXml(file);
        if (treeFile is error) {
            return treeFile;
        } else {
           self.buildTree(treeFile,self.root);
        }
    }
    public function print(){
        io:println(self.root.printXML());
    }
    private function buildTree(xml treeFile,Node node){
            xml eTreeFile = treeFile/<*>;
            eTreeFile.forEach(function(xml item) {
                xmllib:Element eItem = <xmllib:Element>item;
                xml childeren = item/<*>;
                Node child;
                if(childeren.length()>1){
                    child = new Node(
                        eItem.getName().toString(),
                        "", 
                        eItem.getAttributes()["row"].toString(),
                        eItem.getAttributes()["col"].toString());
                }else{
                    child = new Node(
                        eItem.getName().toString(),
                        eItem.getChildren().toString(),
                        eItem.getAttributes()["row"].toString(),
                        eItem.getAttributes()["col"].toString());
                }
                node.addChild(child);
                self.buildTree(item,child);
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


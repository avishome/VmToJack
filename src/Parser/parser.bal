import fileReader;
import ballerina/file;
import ballerina/io;
import ballerina/lang.'xml as xmllib;
import ballerina/stringutils;


public function main(string... args) {
    if (args.length() < 1) {
        io:println("Please enter a source folder");
    } else {
        file:FileInfo[]|error readDirResults = file:readDir(<@untained>args[0]);
        if (readDirResults is error) {
            io:println(readDirResults);
            return;
        } else {
            string code = "";
            foreach file:FileInfo item in readDirResults {
                if (item.getName().endsWith("T.xml")) {
                    io:println("Proccessing file: " + item.getName());
                    Parser|error parser = new (<@untained>args[0] + "/" + item.getName());
                    if (parser is Parser) {
                        var root = parser.recurcive("class");
                        if (root is Node) {
                            root.cleanSubtree();
                            string xmlFile = root.printXML();
                            var wResult = write(xmlFile, <@untained>args[0] + "/" + item.getName().substring(0, <int>item.getName().lastIndexOf("T.")) + ".xml");
                            if (wResult is error) {
                                io:println(wResult);
                            }
                        }
                    }
                }
            }
        }
    }
}

public function write(string content, string path) returns @tainted int|error? {
    io:WritableByteChannel wbc = check io:openWritableFile(path);
    io:WritableCharacterChannel wch = new (wbc, "UTF8");
    var result = wch.write(content, 0);
    closeWc(wch);
    return result;
}

public function closeWc(io:WritableCharacterChannel wc) {
    var result = wc.close();
    if (result is error) {
        io:print("Error occurred while closing character stream");
    }
}

public type Parser object {
    private map<json> addrMap;
    public TokenReader tokener;
    public function __init(string file) returns @tainted error? {
        self.tokener = checkpanic new (file);
        string FullFile = getTranslateFileAsString("files/diqduq.json");
        json js = checkpanic FullFile.fromJsonString();
        self.addrMap = <map<json>>js;
    }
    public function addr(string key) returns json? {
        return self.addrMap[key];
    }
    public function addrExist(string key) returns boolean {
        return self.addrMap.hasKey(key);
    }
    public function recurcive(string key, boolean inDic = true) returns @tainted error|Node|boolean {
        boolean isFound = false;
        Node node = new (key);
        json diqduq;
        if (inDic) {
            diqduq = self.addr(key);
        } else {
            diqduq = [key];
        }
        foreach var item in <json[]>diqduq {
            if (item is string) {
                string itemInWord = item;
                string typeOfItem = "R";
                if (item.length() > 1 && (item[item.length() - 1] == "*" || item[item.length() - 1] == "?")) {
                    typeOfItem = item[item.length() - 1];
                    itemInWord = item.substring(0, item.length() - 1);
                }
                boolean firstIteration = true;
                while (firstIteration || typeOfItem == "*") {
                    firstIteration = false;
                    string[]|boolean correnttoken = self.tokener.getCurrent();
                    if (correnttoken is string[]) {
                        if (itemInWord == correnttoken[0] || itemInWord == correnttoken[1]) {
                            Node child = new (correnttoken[0], correnttoken[1]);
                            if (inDic) {
                                node.addChild(child);
                            } else {
                                node = child;
                            }
                            self.tokener.releaseCurrent();
                            continue;
                        }
                        if (self.addrExist(itemInWord)) {
                            error|Node|boolean res = self.recurcive(itemInWord);
                            if (res is Node) {
                                if (inDic) {
                                    node.addChild(res);
                                } else {
                                    node = res;
                                }
                                continue;
                            }

                        }
                        if (typeOfItem == "*" || typeOfItem == "?") {
                            break;
                        }
                        if (typeOfItem == "R") {
                            if (isFound) {
                                io:println("----------CRITICAL FAIL!!!!----------");
                            }
                            return false;
                        }
                    }
                }
                isFound = true;
            } else {
                foreach var i in <json[]>item {
                    if (i is string) {
                        error|Node|boolean res = self.recurcive(i, false);
                        if (res is Node) {
                            node.addChild(res);
                            isFound = true;
                            break;
                        }
                    }
                }
            }
        }
        return isFound ? node : false;
    }
};

public type TokenReader object {
    private string[]|boolean current = false;
    private string[][] tokens = [];
    private int counter = 1;
    public function __init(string file) returns @tainted error? {
        xml|error tokens = self.readXml(file);
        if (tokens is error) {
            return tokens;
        } else {
            xml etokens = tokens/<*>;
            etokens.forEach(function(xml item) {
                xmllib:Element eItem = <xmllib:Element>item;
                self.tokens.push([eItem.getName().toString(), eItem.getChildren().toString()]);
            });
            foreach ( xml|string item in etokens.elements()) {
                if (item is xml) {
                    xmllib:Element eItem = <xmllib:Element>item;
                    var val = eItem/<*>;
                }
            }
            if (self.tokens.length() > 0) {
                self.current = self.tokens[0];
                self.tokens = self.tokens.slice(1);
            }
        }
    }
    public function getCurrent() returns @tainted string[]|boolean {
        return self.current;
    }
    public function releaseCurrent() {
        if (self.tokens.length() > 0) {
            self.current = self.tokens[0];
            self.tokens = self.tokens.slice(1);
            self.counter += 1;
        } else {
            self.current = false;
        }
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

public function getTranslateFileAsString(string translate) returns @tainted string {
    fileReader:Reader|error reader = new (translate);
    if (reader is fileReader:Reader) {
        string FullFile = "";
        error?| string nextLine = reader.readNext();
        while (nextLine is string) {
            FullFile += nextLine;
            nextLine = reader.readNext();
        }
        return FullFile;
    }
    return "";
}

public type Node object {
    private Node? parent = ();
    private Node[] childeren = [];
    private string value = "";
    private string name = "";
    public function __init(string name, string value = "") {
        self.name = name;
        self.value = value;
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

    public function printXML() returns string {
        return self.printSubTree(0);
    }

    public function cleanSubtree() {
        Node[] newChildren = [];
        foreach var child in self.childeren {
            foreach var c in child.getCleardChilderen() {
                newChildren.push(c);
            }
        }
        self.childeren = newChildren;
    }

    private function getCleardChilderen() returns Node[] {
        Node[] newChildren = [];
        string[] toRemove = ["unaryOp", "subterm3", "subterm2", "subsubexpressionList", "keywordConstant", "subsubroutineCall1", "type", "subClassVarDec", "className", "parameterList1", "subparameterList", "subexpression", "op", "subletStatement", "subtemp1", "subvarDec", "statement", "subVarName", "subVarName1", "subroutineCall", "subsubroutineCall2", "subroutineName", "subexpressionList"];
        foreach var child in self.childeren {
            foreach var c in child.getCleardChilderen() {
                newChildren.push(c);
            }
        }
        if (toRemove.indexOf(self.name) != ()) {
            return newChildren;
        } else {
            self.childeren = newChildren;
            return [self];
        }
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
            return self.getOffset(depth) + "<" + self.name + ">" + res + "</" + self.name + ">\n";
        }
    }
};

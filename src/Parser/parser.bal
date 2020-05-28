import fileReader;
import ballerina/io;
import ballerina/lang.'xml as xmllib;
import ballerina/stringutils;

public function main() {
    Parser|error tree = new ();

    if (tree is Parser) {
        //io:println(tree.addr("class").toJsonString());
        //io:println(tree.tokener.getCurrent().toString());
        var i = tree.recurcive("class", 0);
        if (i is Node) {
            string xmlFile = i.print();
            var wResult = write(xmlFile, "files/test.xml");

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

function getReqMove(int num) returns string {
    string s = "";
    int n = num;
    while (n > 0) {
        s += "| ";
        n -= 1;
    }
    return s;
}


public type Parser object {
    private map<json> addrMap;
    public TokenReader tokener;
    public function __init() returns @tainted error? {
        self.tokener = checkpanic new ();
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
    public function recurcive(string key, int depth, boolean inDic = true) returns @tainted error|Node|boolean {
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
                            Node child = new (correnttoken[1], correnttoken[0]);
                            if (inDic) {
                                node.addChild(child);
                            } else {
                                node = child;
                            }
                            self.tokener.releaseCurrent(depth);
                            continue;
                        }
                        if (self.addrExist(itemInWord)) {
                            //io:println(getReqMove(depth) + "recurcive call for dict: " + item);
                            error|Node|boolean res = self.recurcive(itemInWord, depth + 1);
                            if (res is Node) {
                                if (inDic) {
                                    node.addChild(res);
                                } else {
                                    node = res;
                                }
                                continue;
                            }

                        }
                        //
                        if (typeOfItem == "*" || typeOfItem == "?") {
                            break;
                        }
                        if (typeOfItem == "R") {
                            //io:println(getReqMove(depth) + "dont found result for: " + item);
                            if (isFound) {
                            //the tokener also release tokens but the try fail
                            //io:println(getReqMove(depth) + "----------CRITICAL FAIL!!!!----------");
                            //int err = 1 / 0;
                            }
                            return false;
                        }
                    }
                }
                //io:println(getReqMove(depth) + "found result by role (maybe empety also) for: " + item);
                isFound = true;
            } else {
                foreach var i in <json[]>item {
                    if (i is string) {
                        //io:println(getReqMove(depth) + "recurcive call optional item in list: " + i);
                        error|Node|boolean res = self.recurcive(i, depth + 1, false);
                        if (res is Node) {
                            node.addChild(res);
                            //io:println(getReqMove(depth) + i);
                            isFound = true;
                            //if found maching we must return beacuse the tokener release next token and maybe it stolen by next diqduq..
                            break;
                        }
                    }
                }
            }
        }
        //io:println(getReqMove(depth) + "finish func with found: " + isFound.toString());
        return isFound ? node : false;
    }
};

public type TokenReader object {
    private string[]|boolean current = false;
    private string[][] tokens = [];
    private int counter = 1;
    public function __init() returns @tainted error? {
        xml|error tokens = self.readXml("files/Main.xml");
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
    public function releaseCurrent(int depth) {
        //io:println(getReqMove(depth) + "success(" + self.counter.toString() + "): " + self.current.toString());
        if (self.tokens.length() > 0) {
            self.current = self.tokens[0];
            self.tokens = self.tokens.slice(1);
            self.counter += 1;
        //io:println(getReqMove(depth) + "next(" + self.counter.toString() + "): " + self.current.toString());
        } else {
            self.current = false;
        }
    }
    public function getCounter() returns int {
        return self.counter;
    }
    public function readXml(string path) returns @tainted xml|error {

        io:ReadableByteChannel rbc = check io:openReadableFile(path);

        io:ReadableCharacterChannel rch = new (rbc, "UTF8");

        var xmlResult = rch.readXml();

        var result = rch.close();
        if (result is error) {
        //io:println("Error occurred while closing character stream");
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
    public string value = "";
    public string name = "";
    public function __init(string value, string name = "") {
        self.name = name;
        self.value = value;
    }
    function isLeaf() returns boolean {
        return self.childeren.length() == 0;
    }
    function setParent(Node parent) {
        self.parent = parent;
    }
    function getChilderen() returns Node[] {
        return self.childeren;
    }
    function addChild(Node child) {
        child.setParent(self);
        self.childeren.push(child);
    }
    function print() returns string {
        if (!self.isLeaf()) {
            string res = "<" + self.value + ">";
            foreach var child in self.childeren {
                res += child.print();
            }
            res += "</" + self.value + ">";
            return res;
        } else {
            string res = stringutils:replaceAll(self.value, "&", "&amp;");
            res = stringutils:replaceAll(res, "<", "&lt;");
            res = stringutils:replaceAll(res, "<", "&gt;");
            return "<" + self.name + ">" + res + "</" + self.name + ">";
        }
    }
};

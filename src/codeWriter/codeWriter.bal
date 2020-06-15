import ballerina/io;
import ballerina/lang.'xml as xmllib;
import ballerina/stringutils;

# Prints `Hello World`.

public function main() {
    CodeWriter|error c = new ("files/Square.xml");
    if (c is CodeWriter) {
        var code = c.getCode();
        if (code is string) {
            string res = code;
            res = fillnumbers(res);
            io:println(res);
        } else {
            io:println(c.getErrorStack());
            io:println(c.tree.classVarTable);
            io:println(c.tree.methodVarTable);
        }
    }
}

public function fillnumbers(string res) returns string{
    string res1 = res;
    string[] result = stringutils:split(res1, "\n");
    foreach string line in result{
        string[] words = stringutils:split(line, " ");
        if(words[0] == "function"){
            res1 = stringutils:replaceAll(res1, words[1] + " numberEmpty", words[1] +" "+ words[2]);
        }   
    }
    return res1;
}

const map<string> keybourdConstant = {"true":"push 1\nneg","false":"0","null":"0","this":"pointer 0"};

public type CodeWriter object {
    private Node root;
    private string class = "";
    private string func = "";
    public Tree tree;
    private int size = 0;
    private string errorStack = "";
    private map<string> unaryOp = {"-":"-","~":"neg"};
    public function __init(string file) returns error? {
        Tree|error tree = new (file);
        if (tree is error) {
            return tree;
        } else {
            self.tree = tree;
            self.root = tree.getRoot();
        }
    }
    public function getErrorStack() returns string {
        return self.errorStack;
    }
    private function addErrorToStack(Node node) {
        self.errorStack += "at " + node.getName() + " " + node.getValue() + " " + node.getLocation() + "\n";
    }
    private function generateConstStringCode(string str) returns string {
        string code = "";
        code += "push constant " + str.length().toString() + "\n";
        code += "call String.new 1\n";
        foreach var char in str {
            code += "push constant " + char.toBytes().toString() + "\n";
            code += "call String.appendChar 2\n";
        }

        return code;
    }
    private function getVariableCode(string name) returns string|boolean {
        //io:println("class table"+ self.tree.classVarTable.keys().toString());
        //io:println("method table"+ self.tree.methodVarTable.keys().toString());
        VarRec? rec = self.tree.getMethodRecord(name);
        if (rec is VarRec) {
            return rec.vmType + " " + rec.number.toString();
        } else {
            rec = self.tree.getMethodRecord("this");
            if (rec is VarRec) {
                rec = self.tree.getClassRecord(name);
                if (rec is VarRec) {
                    return rec.vmType + " " + rec.number.toString();
                }
            }
            return false;
        }
    }
    public function getCode() returns @tainted string|boolean {
        return self.getCodeReq(self.root);
    }
    private function getCodeReq(Node node, Node? parent = (),boolean deepScan = true) returns @tainted string|boolean {
        Node[] childeren = node.getChilderen();
        string code = "";
        if (node.getName() == "class") {
            self.class = childeren[1].getValue();
            foreach var child in childeren {
                string|boolean res = self.getCodeReq(child, node);
                if (res is string) {
                    code += res;
                } else {
                    self.addErrorToStack(node);
                    return false;
                }
            }
            self.tree.clearClassTable();
        }

        //class var define (static or field)
        if (node.getName() == "classVarDec") {
            string decType = childeren[0].getValue();
            string decKind = childeren[1].getValue();
            boolean succ = self.tree.addRecord("class", childeren[2].getValue(), decKind, decType);
            if (decType == "field") {
                self.size += 1;
            }
            if (!succ) {
                self.addErrorToStack(node);
                return false;
            }
            int index = 3;
            while (childeren[index].getValue() !== ";") {
                succ = self.tree.addRecord("class", childeren[index + 1].getValue(), decKind, decType);
                if (decType == "field") {
                    self.size += 1;
                }
                if (!succ) {
                    self.addErrorToStack(node);
                    return false;
                }
                index += 2;
            }
        }

        //method var define (var) in method
        if (node.getName() == "varDec") {
            string decType = childeren[0].getValue();
            string decKind = childeren[1].getValue();
            boolean succ = self.tree.addRecord("func", childeren[2].getValue(), decKind,decType);
            if (!succ) {
                self.addErrorToStack(node);
                return false;
            }
            int index = 3;
            while (childeren[index].getValue() !== ";") {
                succ = self.tree.addRecord("func", childeren[index + 1].getValue(),decKind, decType);
                if (!succ) {
                    self.addErrorToStack(node);
                    return false;
                }
                index += 2;
            }
        }

        //the method
        if (node.getName() == "subroutineDec") {
            self.tree.clearMethodTable();
            string returnType = "";
            string funcType = "";
            string funcName = "";
            string constractorCode = "";
            if (childeren[0].getValue() == "method") {
                funcType = "method";
                returnType = childeren[1].getValue();
                funcName = childeren[2].getValue();
                _ = self.tree.addRecord("func", "this", self.class, "arg"); // this to funcName
            }
            if (childeren[0].getValue() == "function") {
                funcType = "function";
                returnType = childeren[1].getValue();
                funcName = childeren[2].getValue();
                //TODO add record
            }
            if (childeren[0].getValue() == "constructor") {
                funcType = "constructor";
                returnType = childeren[1].getValue();
                funcName = childeren[2].getValue();
                _ = self.tree.addRecord("func", "this", self.class, "arg");
                constractorCode = "push constant " + self.size.toString() + "\n" +
                    "call Memory.alloc 1\n" +
                    "pop pointer 0\n";
            }
            //parameter list?
            var test = self.getCodeReq(childeren[4], node); 
            if(test is boolean){
                self.addErrorToStack(node);
                return false;
            }
            boolean|string res = self.getCodeReq(childeren[6], node);
            if (res is boolean) {
                self.addErrorToStack(node);
                return false;
            } else {
                code += "function " + self.class + "." + funcName + " " + self.tree.getFunctionLocalNumber().toString() + "\n";
                code += constractorCode;
                code += res;
                //if (funcType == "constructor") {
                //    code += "push pointer 0\n" +
                //        "return\n";
                //} return sastment
            }
        }

        //parametr to method
        if (node.getName() == "parameterList") {
            int index = 0;
            while (index + 1 < childeren.length()) {
                boolean succ = self.tree.addRecord("func", childeren[index+1].getValue(), childeren[index].getValue(),"arg");
                if (!succ) {
                    self.addErrorToStack(node);
                    return false;
                }
                index += 3;
            }
        }

        //method body
        if (node.getName() == "subroutineBody") {
            foreach var child in childeren {
                if (child.getName() == "varDec" || child.getName() == "statements") {
                    boolean|string res = self.getCodeReq(child, node);
                    if (res is boolean) {
                        self.addErrorToStack(node);
                        return false;
                    } else {
                        code += res;
                    }
                }
            }
        }

        //in body method
        if (node.getName() == "statements") {
            foreach var child in childeren {
                boolean|string res = self.getCodeReq(child, node);
                if (res is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += res;
                }
            }
        }

        if (node.getName() == "returnStatement"){
            if(childeren[1].getName() == "expression"){
                var expression = self.getCodeReq(childeren[1], node);
                if (expression is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += expression;
                }
            } else {
                code += "push constant 0\n";
            }
            code += "return\n";
        }

        if (node.getName() == "doStatement"){
            //TODO NO TREAT ROF subsubroutineCall2 .ID(PARAMS)
            string caller = "";
            string firstArg = "";
            boolean isOneWordDefin = childeren[2].getChilderen().length()>3;
            if(isOneWordDefin){
                caller = "call " + childeren[1].getValue() +"."+ childeren[2].getChilderen()[1].getValue()  + " numberEmpty";
            } else {
                caller = "call " + self.class +"."+childeren[1].getValue() + " numberEmpty";
            }
            //clac first arg (is known obj?)
            var varibale = self.getVariableCode(childeren[1].getValue());
            if(varibale is boolean){
                if(isOneWordDefin){ //is freind in our class
                    firstArg = "push pointer 0 " + "\n";
                }
            } else{
                firstArg = "push " + varibale + "\n";
            }
            code += firstArg;
            var subroutineCall = self.getCodeReq(childeren[2], node);
            if (subroutineCall is boolean) {
                self.addErrorToStack(node);
                return false;
            } else {
                code += subroutineCall;
            }
            code += caller + "\n";
            code += "pop temp 0 \n";
        }

        if (node.getName() == "expression") {
            boolean|string term = self.getCodeReq(childeren[0], node);
            if (term is boolean) {
                self.addErrorToStack(node);
                return false;
            } else {
                code += term;
            }
            string? op;
            int index = 1;
            map<string> addrMap = {"+": "ADD","-" : "SUB","=": "EQ",">": "GT","<" : "LT",
            "&" : "AND","|" :"OR","*":"call Math.multiply 2","/":"call Math.divide 2"};
            while (index+1 < childeren.length()) {
                term = self.getCodeReq(childeren[index+1], node);
                if (term is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += term;
                }

                op = addrMap[childeren[index].getValue()];
                if (op is string) {
                    code += op  + "\n";
                } else {
                    io:println("op "+ childeren[index].getValue() +" not found");
                }

                index =+ 2;
            }

            return code;
        }
        if (node.getName() == "subroutineCall") {
            if(childeren.length() == 3) {
                return self.getCodeReq(childeren[1], node);
            }
            else {return self.getCodeReq(childeren[3], node);}
        }

        if (node.getName() == "expressionList"){
            boolean|string expression;
            int index = 0;
            while (index < childeren.length()) {
                expression = self.getCodeReq(childeren[index], node);
                if (expression is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += expression;
                } 
                index += 1;
            }
            return code;
        }
        if(node.getName() == "ifStatement"){
            boolean|string expression = self.getCodeReq(childeren[2], node);
                if (expression is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else { 
                    code += expression;
                    code += "not \n";
                    code += "if-goto FALSEIF1 \n";}
            boolean|string statements = self.getCodeReq(childeren[4], node);
                if (statements is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += statements;
                }
            if(childeren.length() == 8){
                code += "goto ENDIF \n";
                code+= "label FALSEIF1 \n";
                statements = self.getCodeReq(childeren[7], node);
                if (statements is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += statements;
                }
                code+= "label ENDIF1 \n";
            } else {
                code+= "label FALSEIF1 \n";
            }
        }

        if(node.getName() == "elseifStatement"){
            var statements = self.getCodeReq(childeren[2], node);
            if (statements is boolean) {
                self.addErrorToStack(node);
                return false;
            } else {
                code += statements;
            }
        }

        if(node.getName() == "whileStatement"){
            code += "label WHILEBOOLEAN1";
            boolean|string expression = self.getCodeReq(childeren[2], node);
                if (expression is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else { 
                    code += expression;
                    code += "not \n";
                    code += "if-goto EXITWHILE1 \n";}
            boolean|string statements = self.getCodeReq(childeren[4], node);
                if (statements is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += statements;
                    code += "goto WHILEBOOLEAN1 \n";
                }
            code+= "label EXITWHILE1 \n";
        }
        if (node.getName() == "term") {
            match childeren[0].getName() {
                "integerConstant" => {
                    code += "push constant "+childeren[0].getValue() + "\n";
                }
                "stringConstant" => {
                    code += self.generateConstStringCode(childeren[0].getValue()) + "\n";
                }
                "identifier" => {
                    if(childeren.length()>1 && childeren[1].getName() == "subroutineCall"){
                        //same code as in do.

                        string caller = "";
                        string firstArg = "";
                        boolean isOneWordDefin = childeren[1].getChilderen().length()>3;
                        if(isOneWordDefin){
                            caller = "call " + childeren[0].getValue() +"."+ childeren[1].getChilderen()[1].getValue()  + " numberEmpty";
                        } else {
                            caller = "call " + self.class +"."+childeren[0].getValue() + " numberEmpty";
                        }
                        //clac first arg (is known obj?)
                        var varibale = self.getVariableCode(childeren[0].getValue());
                        if(varibale is boolean){
                            if(isOneWordDefin){ //is freind in our class
                                firstArg = "push pointer 0 " + "\n";
                            }
                        } else{
                            firstArg = "push " + varibale + "\n";
                        }
                        code += firstArg;
                        var subroutineCall = self.getCodeReq(childeren[1], node);
                        if (subroutineCall is boolean) {
                            self.addErrorToStack(node);
                            return false;
                        } else {
                            code += subroutineCall;
                        }
                        code += caller + "\n";

                        //


                        return code;
                    } else{
                        var varibale = self.getVariableCode(childeren[0].getValue());
                        if(varibale is boolean){
                            io:println("Variable "+childeren[0].getValue()+" is not declared");
                            self.addErrorToStack(node);
                        } else{

                            code += "push "+ varibale + "\n";

                            if(childeren.length()>2 && childeren[1].getValue() == "["){
                                boolean|string experssion = self.getCodeReq(childeren[2], node);
                                if (experssion is boolean) {
                                    self.addErrorToStack(node);
                                    return false;
                                } else {
                                    code += experssion;
                                }
                                code += "add \n";
                            }
                        }
                    }

                } //var name/var name [exprtion]
                "keyword" => {
                    string? keybourd_constant = keybourdConstant[childeren[0].getValue()];
                    if(keybourd_constant is string){
                        code += "push " + keybourd_constant + "\n";
                    }
                }  //true false null this
                "unaryOp" => {
                    string? unary_op = self.unaryOp[childeren[0].getValue()];
                    boolean|string term = self.getCodeReq(childeren[1], node);
                    if (term is boolean) {
                        self.addErrorToStack(node);
                        return false;
                    } else {
                        code += term;
                    }
                    if(unary_op is string){
                        code += "push " + unary_op + "\n";
                    } else {
                        self.addErrorToStack(node);
                        return false;
                    }
                }
                "symbol" => {
                    if(childeren[0].getValue() == "("){
                        boolean|string term = self.getCodeReq(childeren[1], node);
                        if (term is boolean) {
                            self.addErrorToStack(node);
                            return false;
                        } else {
                            code += term;
                        }
                    }
                }
            }
            return code;
        }
        // '=' function in method
        if (node.getName() == "letStatement") {
            string variable = "";
            var dest = self.getVariableCode(childeren[1].getValue());
            if (dest is boolean) {
                io:println("Variable "+childeren[1].getValue()+" is not declared");
                self.addErrorToStack(node);
                return false;
            } else {
                variable = dest;
            }
            if (childeren[2].getValue() == "[") {
                boolean|string expression = self.getCodeReq(childeren[3], node);
                if (expression is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += "push " + variable + "\n";
                    code += expression;
                    code += "add";
                    expression = self.getCodeReq(childeren[6], node);
                    if (expression is boolean) {
                        self.addErrorToStack(node);
                        return false;
                    } else {
                        code += expression;
                    }
                    code += "pop temp 0\n";
                    code += "pop pointer 1\n";
                    code += "push temp 0\n";
                    code += "pop that 0\n";
                }
            } else {
                boolean|string expression = self.getCodeReq(childeren[3], node);
                if (expression is boolean) {
                    self.addErrorToStack(node);
                    return false;
                } else {
                    code += expression;
                }
                code += "pop " + variable + "\n";
            }
        }
        if(code == ""){
            //io:print(node.printXML() + "\n");
        }
        //TODO Code writing here
        return code;
    }
};

public type VarRec record {|
    string jackType;
    string vmType;
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

    public function getLocation() returns string {
        return self.row + ":" + self.col;
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
    public map<VarRec> classVarTable = {};
    public map<VarRec> methodVarTable = {};
    private int localT = 0;
    private int argT = 0;
    private int fieldT = 0;
    private int staticT = 0;
    private int localFuncN = 0;
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
        self.fieldT=0;
    }
    public function getFunctionLocalNumber() returns int {
        return self.localT; // i change from localFuncN
    }
    public function clearMethodTable() {
        self.methodVarTable = {};
        self.localT=0;
        self.argT=0;
    }
    public function addRecord(string fromTable, string name, string varKind, string varType) returns boolean {
        int num = 0;
        string vmType = "";
        match varType {
            "field" => {
                num = self.fieldT;
                self.fieldT += 1;
                vmType = "this";
            }
            "static" => {
                num = self.staticT;
                self.staticT += 1;
                vmType = "static";
            }
            "var" => {
                num = self.localT;
                self.localT += 1;
                vmType = "local";
                if (fromTable == "func") {
                    self.localFuncN += 1;
                }
            }
            "arg" => {
                num = self.argT;
                self.argT += 1;
                vmType = "argument";
            }
            _=>{
                io:println("invalid variable identifier: " + varType);
                return false;
            }
        }
        if (fromTable == "class") {
            if (self.classVarTable[name] is VarRec) {
                io:println("variable "+ name + " is declared already");
                return false;
            } else {
                self.classVarTable[name] = {jackType: varKind, vmType: vmType, number: num};
                return true;
            }
        } else {
            if (self.methodVarTable[name] is VarRec) {
                io:println("variable "+ name + " is declared already");
                return false;
            } else {
                self.methodVarTable[name] = {jackType: varKind, vmType: vmType, number: num};
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


import fileReader;
import ballerina/lang.'xml as xmllib;
import ballerina/io;
import Tokenizer;

public function main() {
    xmllib:Element tokens = <xmllib:Element> xml `<tokens/>`;
    xml listxml = xml` `;
    Tree | error tree = new();

    if(tree is Tree){
        io:println(tree.addr("class").toJsonString());
        io:println(tree.tokener.getCurrent().toString());
        var i = tree.recurcive("class");
    }


}


public type Tree object {
    private map<json> addrMap;
    public T tokener;
    public function __init() returns @tainted error? {
        self.tokener = checkpanic new();
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
    public function recurcive(string key, boolean inDic = true) returns @tainted error | xmllib:Element? | boolean{
        boolean isFound = false;
        json diqduq;
        if(inDic){
            diqduq = self.addr(key);
        } else{
            diqduq = [key];
        }
        foreach var item in <json[]>diqduq {
            if(item is string){
                string itemInWord = item;
                string typeOfItem = "R";
                if(item.length()>0 && (item[item.length()-1] == "*" || item[item.length()-1] == "?")){
                    typeOfItem = item[item.length()-1];
                    itemInWord = item.substring(0,item.length()-1);
                }
                boolean firstIteration = true;
                while (firstIteration || typeOfItem == "*") {
                    firstIteration = false;
                    Tokenizer:Token correnttoken = <Tokenizer:Token>trap self.tokener.getCurrent();
                   if(itemInWord == correnttoken.tokenType || itemInWord == correnttoken["arg1"].toString()) {
                       self.tokener.releaseCurrent();
                       continue;
                   }
                   if(self.addrExist(itemInWord)){
                       io:println("recurcive call for dict: "+itemInWord);
                       error | xmllib:Element? | boolean res = self.recurcive(itemInWord);
                       if(res is boolean && res){
                            continue;
                       }

                   }
                   //
                   if(typeOfItem == "*" || typeOfItem == "?"){break;}
                   if(typeOfItem == "R"){
                       //io:println("dont found result for: " +itemInWord);
                       if(isFound){
                           //the tokener also release tokens but the try fail
                            io:println("----------CRITICAL FAIL!!!!----------");
                            io:println("at line: " + correnttoken["arg2"].toString() + " at place: " + correnttoken["arg3"].toString());
                            io:println("must contain: " + itemInWord);
                            io:println("~~~~~END REPORT!!!!~~~~~~");
                       }
                       return false;
                   }
                }
                io:println("found result by role (maybe empety also) for: " +itemInWord);
                isFound = true;
            } else{
                foreach var i in <json[]>item{
                    if(i is string){
                        io:println("recurcive call optional item in list: "+i);
                        error | xmllib:Element? | boolean res = self.recurcive(i,false);
                        if(res is boolean && res){
                            io:println(i);
                            isFound = true;
                            //if found maching we must return beacuse the tokener release next token and maybe it stolen by next diqduq..
                            break;
                        }
                    }
                }
            }
        }
        io:println("finish func with found: "+ isFound.toString());
        return isFound;
    }
};

public type T object {
    private Tokenizer:Tokenizer  parser;
    private Tokenizer:Token | boolean buffer;
    public function __init() returns @tainted error? {
        fileReader:Reader | error reader = new ("files/Main.jack");
        if (reader is fileReader:Reader) {
            Tokenizer:Tokenizer | error p = new (reader);
            if (p is Tokenizer:Tokenizer) {
                self.parser = <Tokenizer:Tokenizer>p;
                self.buffer = self.parser.getNextToken();
                    //Tokenizer:Token token = parser.getNextToken();
                } else{panic error("no reader");}
            } else {panic error("no file");}
            
    }
    public function getCurrent() returns @tainted error | Tokenizer:Token | boolean  {
        if(self.buffer is boolean){
            self.buffer = self.parser.getNextToken();
        }
        return self.buffer;
    }
    public function releaseCurrent(){
        self.buffer = self.parser.getNextToken();
    }
};

public function getTranslateFileAsString(string translate) returns @tainted string {
        fileReader:Reader | error reader = new (translate);
        if (reader is fileReader:Reader) {
            string FullFile = "";
            error? | string nextLine = reader.readNext();
            while (nextLine is string) {
                FullFile += nextLine;
                nextLine = reader.readNext();
            }
            return FullFile;
        }
        return "";
    }
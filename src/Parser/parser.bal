import fileReader;
import ballerina/lang.'xml as xmllib;
import ballerina/io;
import Tokenizer;

# Prints `Hello World`.
# 

public function main() {
    xmllib:Element tokens = <xmllib:Element> xml `<tokens/>`;
    xml listxml = xml` `;
    T | error tok = new();
    if(tok is T){
        io:print(tok.getCurrent().toString());
        tok.releaseCurrent();
        io:print(tok.getCurrent().toString());
    }
}

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


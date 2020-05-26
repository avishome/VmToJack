import fileReader;
import ballerina/io;
import ballerina/lang.'int as ints;
import ballerina/stringutils;

public function main() {
    int i= 0;
    fileReader:Reader | error reader = new ("files/main.jack");
    if (reader is fileReader:Reader) {
        Tokenizer | error parser = new (reader);
        if (parser is Tokenizer) {
            while (true) {
                Token token = parser.getNextToken();
                match token.tokenType {
                    //SYMBOL | KEYWORD | IDENTIFIER | INTEGER_CONSTANT | STRING_CONSTANT
                    SYMBOL => {
                        io:println("Type: " + SYMBOL + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    KEYWORD => {
                        io:println("Type: " + KEYWORD + " | Value: " + token["arg1"].toString()  + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    IDENTIFIER => {
                        io:println("Type: " + IDENTIFIER + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    INTEGER_CONSTANT => {
                        io:println("Type: " + INTEGER_CONSTANT + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    STRING_CONSTANT => {
                        io:println("Type: " + STRING_CONSTANT + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    
                    _ => {
                        io:println("Type: " + "EOF" + " | Type: " + token["arg1"].toString());
                    }
                }
                if (token.tokenType == EOF || token.tokenType == ERROR) {
                    if (token.tokenType == ERROR) {
                        io:println("Parsing error at row: " + token["arg1"].toString() + " place: " + token["arg2"].toString() + " in file \"text.vm\"");
                    }
                    break;
                }
            }
        } else {
            io:println(parser);
        }
    }
}
 
public const CLASS = "CLASS";
public const CONSTRUCTOR = "CONSTRUCTOR";
public const FUNCTION = "FUNCTION";
public const METHOD = "METHOD";
public const FIELD = "FIELD";
public const STATIC = "STATIC";
public const VAR = "VAR";
public const INT = "INT";
public const CHAR = "CHAR";
public const BOOLEAN = "BOOLEAN";
public const VOID = "VOID";
public const TRUE = "TRUE";
public const FALSE = "FALSE";
public const NULL = "NULL";
public const THIS = "THIS";
public const LET = "LET";
public const DO = "DO";
public const IF = "IF";
public const ELSE = "ELSE";
public const WHILE = "WHILE";
public const RETURN = "RETURN";

public type KEYWORD_TYPE CLASS | CONSTRUCTOR | FUNCTION | METHOD | FIELD | STATIC | VAR | INT | CHAR | BOOLEAN | VOID | TRUE | FALSE | NULL | THIS | LET | DO | IF | ELSE | WHILE | RETURN;

public const BLOCK_OPEN = "BLOCK_OPEN";
public const BLOCK_CLOSE = "BLOCK_CLOSE";
public const ARR_OPEN = "ARR_OPEN";
public const ARR_CLOSE = "ARR_CLOSE";
public const ROUND_OPEN = "ROUND_OPEN";
public const ROUND_CLOSE = "ROUND_CLOSE";
public const ADD = "ADD";
public const SUB = "SUB";
public const NEG = "NEG";
public const EQ = "EQ";
public const GT = "GT";
public const LT = "LT";
public const AND = "AND";
public const OR = "OR";
public const MULT = "MULT";
public const DIV = "DIV";
public const POINT = "POINT";
public const COMMA = "COMMA";
public const SEMICOLON = "SEMICOLON";

public type SYMBOL_TYPE BLOCK_OPEN | BLOCK_CLOSE | ARR_OPEN | ARR_CLOSE | ROUND_OPEN | ROUND_CLOSE | ADD | SUB | NEG | EQ | GT | LT | AND | OR | DIV | POINT | COMMA | SEMICOLON;

public const SYMBOL = "SYMBOL";
public const KEYWORD = "KEYWORD";
public const IDENTIFIER = "IDENTIFIER";
public const INTEGER_CONSTANT = "INTEGER_CONSTANT";
public const STRING_CONSTANT = "STRING_CONSTANT";
public const EOF = "EOF";
public const ERROR = "ERROR";

public type TOKEN_TYPE SYMBOL | KEYWORD | IDENTIFIER | INTEGER_CONSTANT | STRING_CONSTANT | EOF | ERROR;

public type Token record {|
    TOKEN_TYPE tokenType;
    string | int arg1?;
    string | int arg2?;
    string | int arg3?;
|};

public type Tokenizer object {
    private fileReader:Reader reader;
    private int row = 1;
    private int fromRowStart = 0;
    private string[] buffer = [];
    public function __init(fileReader:Reader reader) returns @tainted error? {
        self.reader = reader;
    }
    public function getNextToken() returns @tainted Token {
        self.readWhiteChar();
        while (self.endOfLine()) {
        }
        if (self.endOfFile()) {
            return {tokenType: EOF};
        }
        if (self.matchWord("+")) {
            return self.handle0Args(SYMBOL, ADD);
        }
        if (self.matchWord("-")) {
            return self.handle0Args(SYMBOL, SUB);
        }
        if (self.matchWord("~")) {
            return self.handle0Args(SYMBOL, NEG);
        }
        if (self.matchWord("=")) {
            return self.handle0Args(SYMBOL, EQ);
        }
        if (self.matchWord(">")) {
            return self.handle0Args(SYMBOL, GT);
        }
        if (self.matchWord("<")) {
            return self.handle0Args(SYMBOL, LT);
        }
        if (self.matchWord("&")) {
            return self.handle0Args(SYMBOL, AND);
        }
        if (self.matchWord("|")) {
            return self.handle0Args(SYMBOL, OR);
        }
        if (self.matchWord(",")) {
            return self.handle0Args(SYMBOL, COMMA);
        }
        if (self.matchWord(";")) {
            return self.handle0Args(SYMBOL, SEMICOLON);
        }
        if (self.matchWord("*")) {
            return self.handle0Args(SYMBOL, MULT);
        }
        if (self.matchWord(":")) {
            return self.handle0Args(SYMBOL, DIV);
        }
        if (self.matchWord(".")) {
            return self.handle0Args(SYMBOL, POINT);
        }
        if (self.matchWord("{")) {
            return self.handle0Args(SYMBOL, BLOCK_OPEN);
        }
        if (self.matchWord("}")) {
            return self.handle0Args(SYMBOL, BLOCK_CLOSE);
        }
        if (self.matchWord("[")) {
            return self.handle0Args(SYMBOL, ARR_OPEN);
        }
        if (self.matchWord("]")) {
            return self.handle0Args(SYMBOL, ARR_CLOSE);
        }
        if (self.matchWord("(")) {
            return self.handle0Args(SYMBOL, ROUND_OPEN);
        }
        if (self.matchWord(")")) {
            return self.handle0Args(SYMBOL, ROUND_CLOSE);
        }

        if (self.matchWord("return")) {
            return self.handle0Args(KEYWORD, RETURN);
        }
        if (self.matchWord("while")) {
            return self.handle0Args(KEYWORD, WHILE);
        }
        if (self.matchWord("else")) {
            return self.handle0Args(KEYWORD, ELSE);
        }        
        if (self.matchWord("if")) {
            return self.handle0Args(KEYWORD, IF);
        }
        if (self.matchWord("do")) {
            return self.handle0Args(KEYWORD, DO);
        }
        if (self.matchWord("let")) {
            return self.handle0Args(KEYWORD, LET);
        }
        if (self.matchWord("this")) {
            return self.handle0Args(KEYWORD, THIS);
        }
        if (self.matchWord("null")) {
            return self.handle0Args(KEYWORD, NULL);
        }
        if (self.matchWord("false")) {
            return self.handle0Args(KEYWORD, FALSE);
        }
        if (self.matchWord("true")) {
            return self.handle0Args(KEYWORD, TRUE);
        }
        if (self.matchWord("void")) {
            return self.handle0Args(KEYWORD, VOID);
        }
        if (self.matchWord("boolean")) {
            return self.handle0Args(KEYWORD, BOOLEAN);
        }
        if (self.matchWord("var")) {
            return self.handle0Args(KEYWORD, VAR);
        }
        if (self.matchWord("int")) {
            return self.handle0Args(KEYWORD, INT);
        }
        if (self.matchWord("char")) {
            return self.handle0Args(KEYWORD, CHAR);
        }
        if (self.matchWord("static")) {
            return self.handle0Args(KEYWORD, STATIC);
        }
        if (self.matchWord("field")) {
            return self.handle0Args(KEYWORD, FIELD);
        }
        if (self.matchWord("method")) {
            return self.handle0Args(KEYWORD, METHOD);
        }
        if (self.matchWord("class")) {
            return self.handle0Args(KEYWORD, CLASS);
        }
        if (self.matchWord("constructor")) {
            return self.handle0Args(KEYWORD, CONSTRUCTOR);
        }
        if (self.matchWord("function")) {
            return self.handle0Args(KEYWORD, FUNCTION);
        }
        if (self.matchWord("\"")) {
            string tempstr = "";
            while (!self.matchWord("\"")) {
                string | boolean chr = self.getNextChar();
                if(chr is boolean){
                    break;
                }
                tempstr=tempstr + chr.toString();
            }
            return self.handle0Args(STRING_CONSTANT, tempstr);
        }

        int | boolean number = self.readNumber();
        if (number is int) {
            return self.handle0Args(INTEGER_CONSTANT, number.toString());
        }
        [string, string] | boolean word = self.readWord();
        if (!(word is boolean)) {
            return self.handle0Args(IDENTIFIER, word[0]);
        }

        if (self.matchWord("//")) {
            while (true) {
                if (self.endOfFile() || self.endOfLine()) {
                    break;
                }
                _ = self.getNextChar();
            }
            return self.getNextToken();
        }
        return {tokenType: ERROR, arg1: self.row, arg2: self.fromRowStart};
    }
    function handle0Args(TOKEN_TYPE aType, string arg1) returns @tainted Token {
        return {tokenType: aType, arg1: arg1, arg2: self.row, arg3: self.fromRowStart};
    }


    function readWhiteChar() {
        string | boolean char = self.getNextChar();
        while (char is string && (char == " " || char == "\t")) {
            char = self.getNextChar();
        }
        if (char is string) {
            self.buffer.push(char);
        }
    }

    function endOfLine() returns @tainted boolean {
        self.readWhiteChar();
        if (self.matchWord("//")) {
            string | boolean char = self.getNextChar();
            while (true) {
                if (char is string && (char == "" || char == "\n" || char == "\r")) {
                    return true;
                }
                if (char is boolean) {
                    return false;
                }
                char = self.getNextChar();
            }
        }
        if (self.matchWord("/**")) {
            string | boolean char;
            while (!self.matchWord("*/")) {
                char = self.getNextChar();
                if (char is boolean) {
                    return false;
                }
            }
        }
        string | boolean char = self.getNextChar();
        if (char is string && (char == "" || char == "\n" || char == "\r")) {
            return true;
        }
        if (char is string) {
            if(char != "/"){
                self.buffer.push(char);
            }
            else{
                //here there is problem thatavoid us us / char for divede
            }
        }
        return false;
    }

    function endOfFile() returns @tainted boolean {
        self.readWhiteChar();
        if (self.matchWord("//")) {
            string | boolean char = self.getNextChar();
            while (true) {
                if (char is string && (char == "" || char == "\n" || char == "\r")) {
                    self.buffer.push("\n");
                    return false;
                }
                if (char is boolean) {
                    return true;
                }
                char = self.getNextChar();
            }
        }
        string | boolean char = self.getNextChar();
        if (char is boolean) {
            return true;
        }
        if (char is string) {
            self.buffer.push(char);
        }
        return false;
    }

    function readNumber() returns @tainted int | boolean {
        string number = "";
        string[] buffer = self.buffer.clone();
        int leftInBuffer = buffer.length();
        while (true) {
            string | boolean char = self.getNextChar();
            if (char is boolean) {
                break;
            } else {
                int | error res = ints:fromString(char);
                if (res is error) {
                    self.buffer.push(char);
                    if (leftInBuffer == 0) {
                        buffer.push(char);
                    }
                    break;
                } else {
                    number += char;
                    if (leftInBuffer > 0) {
                        leftInBuffer -= 1;
                    } else {
                        buffer.push(char);
                    }
                }
            }
        }
        int | error res = ints:fromString(number);
        if (res is error) {
            self.buffer = buffer;
            return false;
        } else {
            return res;
        }
    }

    function matchWord(string word) returns boolean {
        string[] buffer = self.buffer.clone();
        int leftInBuffer = buffer.length();
        foreach string c in toArray(word) {
            string | boolean char = self.getNextChar();
            //io:println("word:"+word +" c:"+c +" char:"+ char.toString());
            if (char is boolean) {
                self.buffer = buffer;
                return false;
            } else if (char != c) {
                if (leftInBuffer == 0) {
                    buffer.push(char);
                }
                self.buffer = buffer;
                return false;
            } else {
                if (leftInBuffer > 0) {
                    leftInBuffer -= 1;
                } else {
                    if(char == "/"){
                        char = ":";
                    }
                    buffer.push(char);
                }
            }
        }
        return true;
    }
    function readWord() returns @tainted boolean | [string, string] {
        string word = "";
        while (true) {
            string | boolean char = self.getNextChar();
            if (char is boolean && word == "") {
                return false;
            } else if (char is boolean) {
                return [word, EOF];
            } else if (stringutils:matches(char, "[a-zA-Z0-9_.]")) {
                word += char;
            } else if (char == "" || char == "\n" || char == "\r") {
                return word != "" ? [word, "EOL"] : false;
            } else if (char == " ") {
                return [word, "SPACE"];
            } else {
                if (word.length()>0){ self.buffer.push(char); return [word, "SPACE"];}
                return false;
            }
        }
        return false;
    }
    function getNextChar() returns @tainted string | boolean {
        if (self.buffer.length() > 0) {
            string char = self.buffer[0];
            self.buffer = self.buffer.slice(1);
            return char;
        }
        if (self.reader.hasNext()) {
            string | error? char = self.reader.readNext();
            if (char is string) {
                if (char == "\n") {
                    self.row += 1;
                    self.fromRowStart = 0;
                } else {
                    self.fromRowStart += 1;
                }
                return char;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
};

function isIn(string char, string[] chars) returns boolean {
    boolean res = false;
    foreach string c in chars {
        if (c == char) {
            return true;
        }
    }
    return false;
}

function toArray(string str) returns string[] {
    string[] array = [];
    foreach string c in str {
        array.push(c);
    }
    return array;
}

function log(any | error content) {
    io:println(content);
}

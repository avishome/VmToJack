import fileReader;
import ballerina/lang.'xml as xmllib;
import ballerina/io;
import Tokenizer;
import ballerina/log;
# Prints `Hello World`.
# 
public function main() {
    xmllib:Element tokens = <xmllib:Element> xml `<tokens/>`;
    xml listxml = xml` `;
    fileReader:Reader | error reader = new ("files/main.jack");
    string writePath = "./files/sample.xml";
    if (reader is fileReader:Reader) {
        Tokenizer:Tokenizer | error parser = new (reader);
        if (parser is Tokenizer:Tokenizer) {
            while (true) {
                Tokenizer:Token token = parser.getNextToken();
                match token.tokenType {
                    "SYMBOL" => {
                        listxml = listxml + (xml `<symbol>${token["arg1"].toString()}</symbol>`);
                        //io:println("Type: " + "SYMBOL" + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    "KEYWORD" => {
                        listxml = listxml + (xml `<keyword>${token["arg1"].toString()}</keyword>`);
                        //io:println("Type: " + "KEYWORD" + " | Value: " + token["arg1"].toString()  + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    "IDENTIFIER" => {
                        listxml = listxml + (xml `<identifier>${token["arg1"].toString()}</identifier>`);
                        //io:println("Type: " + "IDENTIFIER" + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    "INTEGER_CONSTANT" => {
                        listxml = listxml + (xml `<integerConstant>${token["arg1"].toString()}</integerConstant>`);
                        //io:println("Type: " + "INTEGER_CONSTANT" + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    "STRING_CONSTANT" => {
                        listxml = listxml + (xml `<stringConstant>${token["arg1"].toString()}</stringConstant>`);
                        //io:println("Type: " + "STRING_CONSTANT" + " | Value: " + token["arg1"].toString() + " | Line: " + token["arg2"].toString() + " | Place: " + token["arg3"].toString());
                    }
                    
                    _ => {
                        io:println("Type: " + "EOF" + " | Type: " + token["arg1"].toString());
                    }
                }
                if (token.tokenType == Tokenizer:EOF || token.tokenType == Tokenizer:ERROR) {
                    if (token.tokenType == Tokenizer:ERROR) {
                        io:println("Parsing error at row: " + token["arg1"].toString() + " place: " + token["arg2"].toString() + " in file \"text.vm\"");
                    }
                    break;
                }
            }
        } else {
            io:println(parser);
        }
    }
    tokens.setChildren(listxml);
    var wResult = write(tokens, writePath);
    if (wResult is error) {
        log:printError("Error occurred while writing xml: ", wResult);
    } else {
        io:println("Preparing to read the content written");
    }
    
}

public function write(xml content, string path) returns @tainted error? {

    io:WritableByteChannel wbc = check io:openWritableFile(path);

    io:WritableCharacterChannel wch = new (wbc, "UTF8");
    var result = wch.writeXml(content);

    closeWc(wch);
    return result;
}
public function closeWc(io:WritableCharacterChannel wc) {
    var result = wc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream",
                        err = result);
    }
}
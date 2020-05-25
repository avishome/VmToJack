import ballerina/io;

public type Reader object {
    private io:ReadableCharacterChannel sourceChannel;
    private string filePath;
    private boolean isEmpty = false;
    private boolean hasNext = false;
    private string next = "EOF";
    public function __init(string path) returns @tainted error? {
        self.filePath = path;
        io:ReadableByteChannel | error readableFieldResult = io:openReadableFile(self.filePath);
        if (readableFieldResult is error) {
            return readableFieldResult;
        } else {
            self.sourceChannel = new (readableFieldResult, "UTF-8");
            string | error char = self.sourceChannel.read(1);
            if (char is error) {
                self.isEmpty = true;
            } else {
                self.hasNext = true;
                self.next = char;
            }
        }
    }
    public function readNext() returns @tainted error? | string {
        string | error char = self.sourceChannel.read(1);
        if (self.next == "EOF") {
            return error("File is empty. Please check if file is empty by calling \"isEmpty\" before calling this function");
        }
        if (char is error) {
            self.hasNext = false;
            string current = self.next;
            self.next = "EOF";
            return current;
        } else {
            self.hasNext = true;
            string current = self.next;
            self.next = char;
            return current;
        }
    }
    public function hasNext() returns boolean {
        return self.hasNext;
    }
    public function isEmpty() returns boolean {
        return self.isEmpty;
    }
    public function close() returns @tainted error? | boolean {
        var cr = self.sourceChannel.close();
        if (cr is error) {
            return cr;
        } else {
            return true;
        }
    }
};

@echo off
call "C:\Program Files\Ballerina\bin\ballerina.bat" run target\bin\Tokenizer.jar %1
call "C:\Program Files\Ballerina\bin\ballerina.bat" run target\bin\Parser.jar %1
call "C:\Program Files\Ballerina\bin\ballerina.bat" run target\bin\CodeWriter.jar %1
DEL %1\*.xml

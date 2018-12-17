# atomized

A port of [Maxwell Flynn's](https://maxwellflynn.com) HTTP request/response builder/parser [atomizes](https://github.com/tinfoilboy/atomizes).

## Usage

Simply add atomized to your project's dub dependencies. For example: 

```json
"dependencies": {
     "atomized": "~>1.0.0"
}
```

#### Including
All that's necessary to include the library is this: 
```d
import atomized;
```


## Examples

#### Responses
```d
HTTPMessage response = new HTTPMessage;

response.setStatusCode(200)
        .setHeader("Content-Type", "text/plain")
        .setHeader("Connection", "close")
        .setMessageBody("Hello world!");

writeln(response);
```

This results in the following output:  

```
HTTP/1.1 200 OK
Content-Type: text/plain
Connection: close
Content-Length: 12

Hello world!
```

#### Requests
```d
HTTPMessage request = new HTTPMessage;

request.setMethod(MessageMethod.GET)
       .setPath("/")
       .setHeader("Host", "example.com")
       .setHeader("User-Agent", "Test Agent")
       .setHeader("Connection", "keep-alive");

writeln(request);
```

This results in the following output:  

```
GET / HTTP/1.1
User-Agent: Test Agent
Host: example.com
Connection: keep-alive
```

#### Parser
```d
string requestString = "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: Test Agent\r\nConnection: keep-alive\r\n\r\n";

HTTPMessage       request = new HTTPMessage;
HTTPMessageParser parser  = new HTTPMessageParser;

parser.parse(request, requestString);

writeln(request);
```

This results in the following output:  

```
GET / HTTP/1.1
User-Agent: Test Agent
Host: example.com
Connection: keep-alive
```

## License

atomize(s/d) is licensed under the [MIT license](https://github.com/tinfoilboy/atomizes/blob/master/LICENSE.md). 

module atomized;

private static
{
    immutable string CARRIAGE_RETURN  = "\r\n";
    immutable string HTTP_VERSION_1   = "HTTP/1.0";
    immutable string HTTP_VERSION_1_1 = "HTTP/1.1";

    enum MessageParserState: ubyte
    {
        NONE=0,

        PARSING_START_LINE,
        START_LINE_REQUEST,
        START_LINE_RESPONSE,
        HEADER_KEY,
        HEADER_VALUE,
        PARSING_BODY
    }

    immutable string[ushort] statusCodes;

    static this()
    {
        import std.exception: assumeUnique;

        string[ushort] codes = [
            100: "Continue",
            101: "Switching Protocol",
            200: "OK",
            201: "Created",
            202: "Accepted",
            203: "Non-Authoritative Information",
            204: "No Content",
            205: "Reset Content",
            206: "Partial Content",
            300: "Multiple Choice",
            301: "Moved Permanently",
            302: "Found",
            303: "See Other",
            304: "Not Modified",
            307: "Temporary Redirect",
            308: "Permanent Redirect",
            400: "Bad Request",
            401: "Unauthorized",
            402: "Payment Required",
            403: "Forbidden",
            404: "Not Found",
            405: "Method Not Allowed",
            406: "Not Acceptable",
            407: "Proxy Authentication Required",
            408: "Request Timeout",
            409: "Conflict",
            410: "Gone",
            411: "Length Required",
            412: "Precondition Failed",
            413: "Payload Too Large",
            414: "URI Too Long",
            415: "Unsupported Media Type",
            416: "Requested Range Not Satisfiable",
            417: "Expectation Failed",
            418: "I'm a teapot",
            421: "Misdirected Request",
            425: "Too Early",
            426: "Upgrade Required",
            428: "Precondition Required",
            429: "Too Many Requests",
            431: "Request Header Fields Too Large",
            451: "Unavailable for Legal Reasons",
            500: "Internal Server Error",
            501: "Not Implemented",
            502: "Bad Gateway",
            503: "Service Unavailable",
            504: "Gateway Timeout",
            505: "HTTP Version Not Supported",
            506: "Variant Also Negotiates",
            507: "Insufficient Storage",
            510: "Not Extended",
            511: "Network Authentication Required"
        ];

        codes.rehash;

        statusCodes = codes.assumeUnique;
    }

    /**
     * Converts a string to a MessageMethod for use in an HTTPMessage object.
     */
    MessageMethod stringToMessageMethod(const string method)
    {
        with(MessageMethod)
        switch(method)
        {
            case "GET":      return GET;
            case "HEAD":     return HEAD;
            case "POST":     return POST;
            case "PUT":      return PUT;
            case "DELETE":   return DELETE;
            case "CONNECT":  return CONNECT;
            case "TRACE":    return TRACE;
            case "PATCH":    return PATCH;

            default:         return NONE;
        }
    }

    /**
     * To be returned with a status code in a response is a status text describing the
     * status code by text rather than by a code.
     * 
     * This method takes in one of those codes and tries to return a text for it.
     */
    string statusTextFromStatusCode(const ushort statusCode)
    {
        if(statusCode in statusCodes)
        {
            return statusCodes[statusCode];
        }

        return "Undefined";
    }
}

static enum MessageMethod: ubyte
{
    NONE=0,

    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    CONNECT,
    TRACE,
    PATCH
}

class HTTPMessage
{
private:
    /**
     * The HTTP method for this message.
     * 
     * Defaults to `NONE` denoting a response.
     */
    MessageMethod m_method;

    /**
     * A status code for this message.
     * 
     * This is ignored if this is a request, as requests have no notion of statuses.
     */
    ushort m_statusCode;

    /**
     * A status message to be associated with the status code for this message.
     * 
     * Keep blank to use an automatically generated status message.
     */
    string m_statusMessage;

    /**
     * The path for the resource specified in the message. Only used for a request.
     * 
     * Defaults to blank.
     */
    string m_path;

    /**
     * The version used for this HTTP message as a string.
     * 
     * Defaults to "HTTP/1.1"
     */
    string m_version = HTTP_VERSION_1_1;

    /**
     * An associative array of headers.
     */
    string[string] m_headers;

    /**
     * An array of unsigned 8-bit integers used to store message bodies.
     */
    ubyte[] m_body;

public:
    /**
     * Set a header in the map to the value provided.
     */
    HTTPMessage setHeader(const string name, const string value)
    {
        m_headers[name] = value;

        return this;
    }

    /**
     * Set a number of headers based on a generic map of keys and values.
     */
    HTTPMessage setHeaders(const string[string] headers)
    {
        foreach(key, value; headers)
        {
            m_headers[key] = value;
        }

        return this;
    }

    /**
     * Get the string value of a single header from the message.
     */
    pragma(inline)
    string getHeader(const string name)
    {
        return m_headers[name];
    }

    /**
     * Set the associated message method for this message.
     * 
     * Use `NONE` to switch this into a response.
     */
    HTTPMessage setMethod(const MessageMethod method)
    {
        m_method = method;

        return this;
    }

    /**
     * Grab the current method for this message.
     * 
     * Returns `NONE` if this is a response.
     */
    pragma(inline)
    MessageMethod getMethod() const
    {
        return m_method;
    }

    /**
     * Set the path of this message, which will be used if it is a request.
     */
    HTTPMessage setPath(const string path)
    {
        m_path = path;

        return this;
    }

    /**
     * Grab the current associated path of this message.
     */
    pragma(inline)
    string getPath()
    {
        return m_path;
    }

    /**
     * Set the version of this HTTP message to the string specified.
     */
    HTTPMessage setVersion(const string version_)
    {
        m_version = version_;

        return this;
    }

    /**
     * Get the current HTTP version for this message.
     */
    pragma(inline)
    string getVersion()
    {
        return m_version;
    }

    /**
     * Set the status code of this HTTP message.
     */
    HTTPMessage setStatusCode(ushort code)
    {
        m_statusCode = code;
        
        return this;
    }

    /**
     * Get the status code for this message.
     */
    pragma(inline)
    ushort getStatusCode()
    {
        return m_statusCode;
    }

    /**
     * Set the status message of this HTTP message.
     */
    HTTPMessage setStatusMessage(const string message)
    {
        m_statusMessage = message;

        return this;
    }

    /**
     * Get the current status message for this message.
     * 
     * Returns an autogenerated status if one isn't specified.
     */
    pragma(inline)
    string getStatusMessage()
    {
        if (m_statusMessage.length == 0)
        {
            return statusTextFromStatusCode(m_statusCode);
        }
        else
        {
            return m_statusMessage;
        }
    }

    /**
     * Takes the headers added to the message along with
     * the body and outputs it to a `std::string` for use
     * in client/server HTTP messages.
     */
    override string toString()
    {
        import std.conv: to;

        string output;

        // begin by forming the start line of the message
        if (m_method == MessageMethod.NONE)
        {
            output ~= m_version ~ " " ~ m_statusCode.to!string ~ " ";
            
            if (m_statusMessage.length == 0)
            {
                output ~= statusTextFromStatusCode(m_statusCode);
            }
            else
            {
                output ~= m_statusMessage;
            }
        }
        else
        {
            output ~= m_method.to!string ~ " ";
            output ~= m_path ~ " ";
            output ~= m_version;
        }

        // output the status lines line break to move on
        output ~= CARRIAGE_RETURN;

        // output headers to the message string
        foreach(key, value; m_headers)
            output ~= key ~ ": " ~ value ~ CARRIAGE_RETURN;

        // automatically output the content length based on
        // the size of the body member if body isn't empty
        if (m_body.length > 0)
            output ~= "Content-Length: " ~ m_body.length.to!string ~ CARRIAGE_RETURN;

        // seperate headers and body with an extra carriage return
        output ~= CARRIAGE_RETURN;
        output ~= cast(string) m_body;

        return output;
    }

    /**
     * Set the body of this message to an unsigned 8-bit binary value.
     */
    HTTPMessage setMessageBody(const ubyte[] body_)
    {
        m_body = cast(ubyte[]) body_;

        return this;
    }

    /**
     * Set the body of this message to a string value.
     */
    HTTPMessage setMessageBody(const string body_)
    {
        return setMessageBody(cast(ubyte[]) body_);
    }

    /**
     * Get the body array for this message.
     */
    pragma(inline)
    ubyte[] getMessageBody()
    {
        return m_body;
    }

    /**
     * Return the size of the binary body array.
     */
    pragma(inline)
    size_t contentLength()
    {
        return m_body.length;
    }

}

class HTTPMessageParser
{
public:
    /**
     * Parse a std::string to a HTTP message.
     * 
     * Pass in a pointer to an HTTPMessage which is then written to for headers
     * and other message data.
     * 
     * note: this must be a complete HTTP message
     */
    void parse(ref HTTPMessage httpMessage, const string buffer)
    {
        parse(httpMessage, cast(ubyte[]) buffer);
    }

    /**
     * Parse an array of characters to an HTTP message.
     * 
     * Pass in a pointer to an HTTPMessage which is written to for headers and
     * other message data.
     * 
     * note: must be a complete HTTP message.
     */
    void parse(ref HTTPMessage httpMessage, const ubyte[] buffer)
    {
        // begin by parsing the start line without knowing if it is a
        // request or a response by setting as undetermined
        MessageParserState state = MessageParserState.PARSING_START_LINE;
    
        // a temporary string instance used for storing characters of a
        // current line in the message being parsed
        string temp;

        // whether to skip the next character (for a carriage return)
        bool skipNext = false;

        // the current key for a header
        string headerKey;

        // whether or not a message body is present
        bool hasMessageBody = false;

        // the index at which the message body begins
        size_t bodyStartIndex = 0;

        for (size_t index = 0; index < buffer.length; index++)
        {
            ubyte character = buffer[index];

            // skip this character as it was marked
            if (skipNext)
            {
                skipNext = false;

                continue;
            }

            // if we are parsing the body, then we only need to grab an index and break
            // out of this loop as we want to merely insert the data from this array
            // into the body array
            if (state == MessageParserState.PARSING_BODY)
            {
                hasMessageBody = true;

                bodyStartIndex = index;

                break;
            }

            // if we are parsing the start line but neither a response or request
            if (state == MessageParserState.PARSING_START_LINE)
            {
                // if we hit a space, we have to check if the start line begins
                // with the HTTP version or the method verb
                if (character == ' ')
                {
                    // this message has a leading version string, thus it is
                    // a response and not a request
                    if (temp == HTTP_VERSION_1 || temp == HTTP_VERSION_1_1)
                    {
                        httpMessage.setMethod(MessageMethod.NONE);

                        state = MessageParserState.START_LINE_RESPONSE;

                        temp = "";

                        continue;
                    }
                    // this must be a request, so grab the MessageMethod type
                    // for the request, set it, and move on
                    else
                    {
                        httpMessage.setMethod(stringToMessageMethod(temp));

                        state = MessageParserState.START_LINE_REQUEST;
                    
                        temp = "";

                        continue;
                    }
                }
            }
            // do actions for when the start line is a request
            else if (state == MessageParserState.START_LINE_REQUEST)
            {
                // once a space is hit, add the path to the message
                if (character == ' ')
                {
                    httpMessage.setPath(temp);

                    temp = "";

                    continue;
                }
                // when the beginning of a carriage return is hit, add the version string
                // to the message and then skip the following new line character, setting
                // the state of the parser to be parsing headers
                else if (character == '\r')
                {
                    httpMessage.setVersion(temp);

                    temp = "";

                    state = MessageParserState.HEADER_KEY;

                    skipNext = true;

                    continue;
                }
            }
            // do actions for when the start line is a response
            else if (state == MessageParserState.START_LINE_RESPONSE)
            {
                import std.conv: to;

                // if we are at a space, then we have hit the status code for the response
                if (character == ' ')
                {
                    httpMessage.setStatusCode(temp.to!ushort);

                    temp = "";

                    continue;
                }
                // if we are at a carriage return start, then set the status message for
                // the response, this can be blank in which it will use a generated status
                //
                // this will also set the state of the parser to move on to headers
                else if (character == '\r')
                {
                    httpMessage.setStatusMessage(temp);

                    temp = "";

                    state = MessageParserState.HEADER_KEY;

                    skipNext = true;

                    continue;
                }
            }
            // if we are parsing header keys and hit a colon, then the key for the header has
            // been fully parsed and should be added to the temporary key holder
            else if (state == MessageParserState.HEADER_KEY && character == ':')
            {
                headerKey = temp;

                temp = "";

                state = MessageParserState.HEADER_VALUE;

                // HTTP defines that the next character in a header should be a space
                // so skip that for parsing the value of the header
                skipNext = true;

                continue;
            }
            // if we are parsing header values and hit the beginning of a carriage return then
            // it is time to add the header to the message with the key and value, and move the
            // state back to parsing keys
            else if (state == MessageParserState.HEADER_VALUE && character == '\r')
            {
                httpMessage.setHeader(headerKey, temp);

                headerKey = "";
                temp      = "";

                state = MessageParserState.HEADER_KEY;

                // skip the next character as it will just be a newline
                skipNext = true;

                continue;
            }
            // if we are parsing header keys and we hit a carriage return, then we should assume
            // that the headers have ended, and that we are now parsing a message body.
            else if (state == MessageParserState.HEADER_KEY && character == '\r')
            {
                temp = "";

                state = MessageParserState.PARSING_BODY;

                // skip the next character as it'll be a newline
                skipNext = true;

                continue;
            }

            temp ~= character;
        }

        // add the body to the message if it is present
        if (hasMessageBody)
        {
            httpMessage.setMessageBody(
                httpMessage.getMessageBody ~ buffer
            );
        }
    }
}

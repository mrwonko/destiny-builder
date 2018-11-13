import asynchttpserver, asyncdispatch, strformat, strutils, httpclient
from htmlgen import nil
from xmldom import escapeXml
from uri import encodeUrl, decodeURL
from os import getEnv
from system import quit, QuitFailure

const
    envClientId = "CLIENT_ID"
    envClientSecret = "CLIENT_SECRET"
    envApiKey = "API_KEY"
    # frontendJS = staticRead "frontend.js"

type
    loginQueryArguments = tuple
        code: string

proc parseLoginQueryArguments(query: string): loginQueryArguments = # TODO: allow return of error
    # TODO: make this function generic over return type
    var res: loginQueryArguments
    for arg in query.split '&':
        let kv = arg.split('=', 2)
        if kv.len != 2:
            continue
        let
            key = kv[0].decodeUrl(true)
            val = kv[1].decodeUrl(true)
        case key:
            of "code":
                res.code = val
    return res

proc main() = # required because if clientId is a global, it's not gcsafe to use
    let
        clientId = getEnv envClientId
        urlClientId = encodeURL clientId
        clientSecret = getEnv envClientSecret
        urlClientSecret = encodeURL clientSecret
        apiKey = getEnv envApiKey
        urlApiKey = encodeURL apiKey
    
    if clientId == "":
        echo &"{envClientId} not set"
        quit(QuitFailure)
    if clientSecret == "":
        echo &"{envClientSecret} not set"
        quit(QuitFailure)
    if apiKey == "":
        echo &"{envApiKey} not set"
        quit(QuitFailure)
    
    let
        indexHeaders = newHttpHeaders([("Content-Type","text/html")])
        indexContent = "<!DOCTYPE html>\n" & $htmlgen.html(
            htmlgen.head(
                htmlgen.title("Destiny Builder")
            ),
            htmlgen.body(
                htmlgen.p(
                    htmlgen.a(href = &"https://www.bungie.net/en/oauth/authorize?client_id={urlClientId}&response_type=code", "login")
                )
            )
        )

    proc serveIndex(req: Request) {.async, gcsafe.} =
        await req.respond(Http200, indexContent, indexHeaders)
    
    let loginClient = newAsyncHttpClient()
    loginClient.headers = newHttpHeaders({
        "Content-Type": "application/x-www-form-urlencoded",
    })
    proc serveLogin(req: Request) {.async, gcsafe.} =
        let
            args = parseLoginQueryArguments(req.url.query)
            urlCode = encodeUrl(args.code, true)
            reqBody = &"grant_type=authorization_code&code={urlCode}&client_id={urlClientId}&client_secret={urlClientSecret}"
            resp = await loginClient.request(url = "https://www.bungie.net/platform/app/oauth/token/", httpMethod = HttpPost, body = reqBody)
            respBody = await resp.body
        echo &"request body: {reqBody}, request headers: {loginClient.headers}, response status: {resp.status}, response body: {respBody}"
        await req.respond(Http501, "not implemented")

    proc serveFileNotFound(req: Request) {.async, gcsafe.} =
        await req.respond(Http404, "not found")
    
    proc serveMethodNotAllowed(req: Request) {.async, gcsafe.} =
        await req.respond(Http405, "method not allowed")

    proc serve(req: Request) {.async, gcsafe.} =
        # FIXME: use case expression once https://github.com/nim-lang/Nim/issues/9655 is fixed
        var handler: proc(req: Request): Future[void]
        case req.reqMethod:
            of HttpGet:
                case req.url.path:
                    of "/":
                        handler = serveIndex
                    of "/login":
                        handler = serveLogin
                    else:
                        handler = serveFileNotFound
            else:
                handler = serveMethodNotAllowed
        await handler(req)
    
    let server = newAsyncHttpServer()
    waitFor server.serve(Port(8080), serve, address = "127.0.0.1")

when isMainModule:
    main()

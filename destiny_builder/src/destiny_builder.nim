import asynchttpserver, asyncdispatch, strformat, strutils
from htmlgen import nil
from xmldom import escapeXml
from uri import encodeUrl, decodeURL
from os import getEnv
from system import quit, QuitFailure

const
    envClientID = "CLIENT_ID"
    # frontendJS = staticRead "frontend.js"

proc main() = # required because if clientID is a global, it's not gcsafe to use
    let clientID = getEnv(envClientID)
    let urlClientID = encodeURL clientID
    
    if clientID == "":
        echo &"{envClientID} not set"
        quit(QuitFailure)

    proc serveIndex(req: Request) {.async, gcsafe.} =
        let body = htmlgen.html(
            htmlgen.head(
                htmlgen.title(
                    escapeXml "Destiny Builder</title>injected"
                )
            ),
            htmlgen.body(
                htmlgen.p(
                    htmlgen.a(href = &"https://www.bungie.net/en/oauth/authorize?client_id={urlClientID}&response_type=code", "login")
                )
            )
        )
        let headers = newHttpHeaders([("Content-Type","text/html")])
        await req.respond(Http200, "<!DOCTYPE html>\n" & $body, headers)
    
    proc serveLogin(req: Request) {.async, gcsafe.} =
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

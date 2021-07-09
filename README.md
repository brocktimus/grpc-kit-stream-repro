This is a reproduction of a couple of bugs I ran into with grpc_kit.
These are basically just extracting the routeguide_examples and isolating it to a purely server streaming indefinitely call.
Fire up the client and the server and the following things can be witnessed:

1. Eventually the client stops receiving messages, even if they're being sent by the server
2. If you terminate the client with ctrl-c or similar, the server will keep "sending" to the stream

I dug through all the layers I could earlier to no avail and I couldn't figure out what was going on.
I ended up near / within the DS9 calls and at that point I couldn't figure out what was going on. 
I was also debugging the raw sockets at that point.

This is a much paired down easily reproduction of a bug I had.
In that case the server impl was not grpc_kit (entirely diff language) but the problem with the client just "not receiving after a while" was present.
In that case there was some extra debug:
* When we started the call I could see data being received by the rx buffers
* Eventually it just stopped receiving more data at the raw socket level (found using ss -ti)
* This was irrelevant of if I was iterating messages off the stream or not

It's harder to do a reproduction of that one since it involves a lot more languages and everything.
The "default" gRPC client library was fine there and didn't exhibit these issues.
I'm trying to move to grpc_kit so I can use griffin, but the client bug means I can't since grpc and grpc_kit can't exist in the same codebase.

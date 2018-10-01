# pbparsen
Protobuf parser in pure Nim.  
It will return the information regarding Protobuf definition.  
The current implementation able to:

* Getting all messages definition
* Normalize nested message definition within message
* Getting all services definition

Still hasn't supported to parse `enum` or any other type

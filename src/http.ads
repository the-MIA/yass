package HTTP
is
   package Net
   is
      Socket_Error : exception;
   end Net;

   package Server
   is
      procedure Wait;
   end Server;

end HTTP;

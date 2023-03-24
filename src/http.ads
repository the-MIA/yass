package HTTP
is
   package Net
   is
      procedure Wait;
   end Net;

   package Server
   is
      Socket_Error : exception;
   end Server;

end HTTP;

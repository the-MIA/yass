package HTTP
is
   package Net
   is
      Socket_Error : exception;
   end Net;

   package Server
   is
      procedure Wait;
      type HTTP is null record;
      procedure Start;
      procedure Stop;
      procedure Shutdown;
   end Server;

   package Status
   is
   end Status;

   package Response
   is
   end Status;

   package Services
   is
   end Status;

end HTTP;

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
      type Data is null record;
      type URI is null record;
   end Status;

   package Response
   is
      type Data is null record;
      procedure Build (Contents     : String;
                       Body_Message : String);
   end Response;

   package Services
   is
      package Directory is
      end Directory;

      procedure Page_Server;
   end Services;

end HTTP;

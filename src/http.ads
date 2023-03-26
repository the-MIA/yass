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
      function URI (Request : Status.Data) return String;
   end Status;

   package Response
   is
      type Data is null record;
      procedure Build (Content_Type : String;
                       Message_Body : String);
   end Response;

   package Services
   is
      package Directory is
      end Directory;

      procedure Page_Server;
   end Services;

end HTTP;

package HTTP
is
   package Net
   is
      Socket_Error : exception;
   end Net;

   package Status
   is
      type Data is null record;
      function URI (D : Status.Data) return String;
   end Status;

   package Response
   is
      type Data is private;
      procedure Build (Content_Type : String;
                       Message_Body : String;
                       Response     : Data);
   private
      type Data is null record;  
   end Response;

   package Server
   is
      procedure Wait;
      type HTTP is null record;
      type Callback_Access is access function (Request : Status.Data) return Response.Data;
      procedure Start
        (Web_Server : HTTP;
         Name       : String;
         Port       : Natural;
         Callback   : Callback_Access;
         Max_Connection : Positive);

      procedure Stop;
      procedure Shutdown (Web_Server : HTTP);
   end Server;

   package Services
   is
      package Directory
      is
         function Browse (
            Directory_Name    : String;
            Template_Filename : String;
            Request           : Status.Data)
         return String;

      end Directory;

      package Page_Server
      is
         function Callback (Request : Status.Data) return Response.Data;
      end Page_Server;
   end Services;

end HTTP;

--    Copyright 2019-2021 Bartek thindil Jasicki
--
--    This file is part of YASS.
--
--    YASS is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    YASS is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with YASS.  If not, see <http://www.gnu.org/licenses/>.

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Directories; use Ada.Directories;
with Ada.Text_IO.Text_Streams; use Ada.Text_IO.Text_Streams;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Calendar; use Ada.Calendar;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with DOM.Core; use DOM.Core;
with DOM.Core.Documents; use DOM.Core.Documents;
with DOM.Core.Nodes; use DOM.Core.Nodes;
with DOM.Core.Elements; use DOM.Core.Elements;
with DOM.Readers; use DOM.Readers;
with Input_Sources.File; use Input_Sources.File;
with Config; use Config;
with AtomFeed; use AtomFeed;

package body Sitemaps is

   Sitemap: Document;
   Sitemap_File_Name: Unbounded_String;
   Main_Node: DOM.Core.Element;

   procedure Start_Sitemap is
      Sitemap_File: File_Input;
      --## rule off IMPROPER_INITIALIZATION
      Reader: Tree_Reader;
      New_Sitemap: DOM_Implementation;
      Nodes_List: Node_List;
      --## rule on IMPROPER_INITIALIZATION
   begin
      if not Yass_Config.Sitemap_Enabled then
         return;
      end if;
      Sitemap_File_Name :=
        Yass_Config.Output_Directory &
        To_Unbounded_String(Source => Dir_Separator & "sitemap.xml");
      -- Load existing sitemap data
      if Exists(Name => To_String(Source => Sitemap_File_Name)) then
         Open
           (Filename => To_String(Source => Sitemap_File_Name),
            Input => Sitemap_File);
         --## rule off IMPROPER_INITIALIZATION
         Parse(Parser => Reader, Input => Sitemap_File);
         Close(Input => Sitemap_File);
         Sitemap := Get_Tree(Read => Reader);
         --## rule on IMPROPER_INITIALIZATION
         Nodes_List :=
           DOM.Core.Documents.Get_Elements_By_Tag_Name
             (Doc => Sitemap, Tag_Name => "urlset");
         Main_Node := Item(List => Nodes_List, Index => 0);
         Set_Attribute
           (Elem => Main_Node, Name => "xmlns",
            Value => "http://www.sitemaps.org/schemas/sitemap/0.9");
         -- Create new sitemap data
      else
         Sitemap := Create_Document(Implementation => New_Sitemap);
         Main_Node := Create_Element(Doc => Sitemap, Tag_Name => "urlset");
         Set_Attribute
           (Elem => Main_Node, Name => "xmlns",
            Value => "http://www.sitemaps.org/schemas/sitemap/0.9");
         Main_Node := Append_Child(N => Sitemap, New_Child => Main_Node);
      end if;
   end Start_Sitemap;

   procedure Add_Page_To_Sitemap
     (File_Name, Change_Frequency, Page_Priority: String) is
      Url: constant String :=
        To_String(Yass_Config.Base_Url) & "/" &
        Slice
          (To_Unbounded_String(File_Name),
           Length(Yass_Config.Output_Directory & Dir_Separator) + 1,
           File_Name'Length);
      Urls_List, Children_List: Node_List;
      Added, Frequency_Updated, Priority_Updated: Boolean := False;
      Url_Node, Url_Data, Old_Main_Node, Remove_Frequency,
      Remove_Priority: DOM.Core.Element;
      Url_Text: Text;
      Last_Modified: constant String := To_HTTP_Date(Clock);
   begin
      if not Yass_Config.Sitemap_Enabled then
         return;
      end if;
      Urls_List := DOM.Core.Documents.Get_Elements_By_Tag_Name(Sitemap, "loc");
      for I in 0 .. Length(Urls_List) - 1 loop
         if Node_Value(First_Child(Item(Urls_List, I))) /= Url then
            goto End_Of_Loop;
         end if;
         -- Update sitemap entry if exists
         Url_Node := Parent_Node(Item(Urls_List, I));
         Children_List := Child_Nodes(Url_Node);
         for J in 0 .. Length(Children_List) - 1 loop
            if Node_Name(Item(Children_List, J)) = "lastmod" then
               Url_Text := First_Child(Item(Children_List, J));
               Set_Node_Value(Url_Text, Last_Modified);
            elsif Node_Name(Item(Children_List, J)) = "changefreq" then
               if Change_Frequency /= "" then
                  Url_Text := First_Child(Item(Children_List, J));
                  Set_Node_Value(Url_Text, Change_Frequency);
               else
                  Remove_Frequency := Item(Children_List, J);
               end if;
               Frequency_Updated := True;
            elsif Node_Name(Item(Children_List, J)) = "priority" then
               if Page_Priority /= "" then
                  Url_Text := First_Child(Item(Children_List, J));
                  Set_Node_Value(Url_Text, Page_Priority);
               else
                  Remove_Priority := Item(Children_List, J);
               end if;
               Priority_Updated := True;
            end if;
         end loop;
         if Change_Frequency /= "" and not Frequency_Updated then
            Url_Data := Create_Element(Sitemap, "changefreq");
            Url_Data := Append_Child(Url_Node, Url_Data);
            Url_Text := Create_Text_Node(Sitemap, Change_Frequency);
            Url_Text := Append_Child(Url_Data, Url_Text);
         end if;
         if Page_Priority /= "" and not Priority_Updated then
            Url_Data := Create_Element(Sitemap, "priority");
            Url_Data := Append_Child(Url_Node, Url_Data);
            Url_Text := Create_Text_Node(Sitemap, Page_Priority);
            Url_Text := Append_Child(Url_Data, Url_Text);
         end if;
         if Remove_Frequency /= null then
            Url_Node := Remove_Child(Url_Node, Remove_Frequency);
         end if;
         if Remove_Priority /= null then
            Url_Node := Remove_Child(Url_Node, Remove_Priority);
         end if;
         Added := True;
         exit;
         <<End_Of_Loop>>
      end loop;
      -- Add new sitemap entry
      if not Added then
         Url_Node := Create_Element(Sitemap, "url");
         Old_Main_Node := Main_Node;
         Main_Node := Append_Child(Main_Node, Url_Node);
         Main_Node := Old_Main_Node;
         Url_Data := Create_Element(Sitemap, "loc");
         Url_Data := Append_Child(Url_Node, Url_Data);
         Url_Text := Create_Text_Node(Sitemap, Url);
         Url_Text := Append_Child(Url_Data, Url_Text);
         Url_Data := Create_Element(Sitemap, "lastmod");
         Url_Data := Append_Child(Url_Node, Url_Data);
         Url_Text := Create_Text_Node(Sitemap, Last_Modified);
         Url_Text := Append_Child(Url_Data, Url_Text);
         if Change_Frequency /= "" then
            Url_Data := Create_Element(Sitemap, "changefreq");
            Url_Data := Append_Child(Url_Node, Url_Data);
            Url_Text := Create_Text_Node(Sitemap, Change_Frequency);
            Url_Text := Append_Child(Url_Data, Url_Text);
         end if;
         if Page_Priority /= "" then
            Url_Data := Create_Element(Sitemap, "priority");
            Url_Data := Append_Child(Url_Node, Url_Data);
            Url_Text := Create_Text_Node(Sitemap, Page_Priority);
            Url_Text := Append_Child(Url_Data, Url_Text);
         end if;
      end if;
   end Add_Page_To_Sitemap;

   procedure Save_Sitemap is
      SitemapFile: File_Type;
   begin
      if not Yass_Config.Sitemap_Enabled then
         return;
      end if;
      -- If the sitemap file not exists - create or open existing robot.txt file and append address to the sitemap
      if not Exists(To_String(Sitemap_File_Name)) then
         if Exists
             (Containing_Directory(To_String(Sitemap_File_Name)) &
              Dir_Separator & "robots.txt") then
            Open
              (SitemapFile, Append_File,
               Containing_Directory(To_String(Sitemap_File_Name)) &
               Dir_Separator & "robots.txt");
         else
            Create
              (SitemapFile, Append_File,
               Containing_Directory(To_String(Sitemap_File_Name)) &
               Dir_Separator & "robots.txt");
         end if;
         Put_Line
           (SitemapFile,
            "Sitemap: " & To_String(Yass_Config.Base_Url) & "/sitemap.xml");
         Close(SitemapFile);
      end if;
      -- Save the sitemap to the file
      Create(SitemapFile, Out_File, To_String(Sitemap_File_Name));
      Write(Stream => Stream(SitemapFile), N => Sitemap, Pretty_Print => True);
      Close(SitemapFile);
   end Save_Sitemap;

end Sitemaps;

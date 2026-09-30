with Ada.Text_IO;
with Greet;

procedure Template is
begin
    Ada.Text_IO.Put_Line (Greet.Message ("world"));
end Template;

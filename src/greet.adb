package body Greet is

    function Message (Name : String) return String is
    begin
        return "Hello, " & Name & "!";
    end Message;

end Greet;

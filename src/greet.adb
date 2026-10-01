package body Greet is

    function Message (Name : String) return String is
    begin
        return Prefix & Name & Suffix;
    end Message;

end Greet;

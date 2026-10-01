package Greet is

    Prefix : constant String := "Hello, ";
    Suffix : constant String := "!";

    function Message (Name : String) return String
    with
        Pre  => Name'Length <= Natural'Last - Prefix'Length - Suffix'Length,
        Post => Message'Result = Prefix & Name & Suffix;
    --  Returns a greeting for Name.

end Greet;

with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;
with Greet;

package body Greet_Tests is

    package Caller is new AUnit.Test_Caller (Fixture);

    procedure Test_Message (T : in out Fixture) is
        pragma Unreferenced (T);
    begin
        Assert (Greet.Message ("world") = "Hello, world!", "unexpected greeting");
    end Test_Message;

    function Suite return AUnit.Test_Suites.Access_Test_Suite is
        Result : constant AUnit.Test_Suites.Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
    begin
        Result.Add_Test (Caller.Create ("Greet.Message", Test_Message'Access));
        return Result;
    end Suite;

end Greet_Tests;

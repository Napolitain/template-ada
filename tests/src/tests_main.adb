with Ada.Command_Line;
with AUnit;
use type AUnit.Status;
with AUnit.Reporter.Text;
with AUnit.Run;
with Greet_Tests;

procedure Tests_Main is
    function Runner is new AUnit.Run.Test_Runner_With_Status (Greet_Tests.Suite);
    Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
    if Runner (Reporter) /= AUnit.Success then
        Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
    end if;
end Tests_Main;

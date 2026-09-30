with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Greet_Tests is

    type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

    procedure Test_Message (T : in out Fixture);

    function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Greet_Tests;

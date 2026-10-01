--  Coverage gate with GNATcoverage (source instrumentation, stmt+decision).
--  Instruments the template crate, runs the AUnit tests, writes the reports and fails below the
--  minimum line coverage (first argument, default 80). The main (template.adb) is excluded.
--
--  From tests/: alr run coverage [--args=90]
--  Outputs: violation report on stdout, obj/coverage/*.xcov, obj/cobertura/cobertura.xml.

with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Float_Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;

procedure Coverage is
    package CL renames Ada.Command_Line;
    package Dirs renames Ada.Directories;
    package Env renames Ada.Environment_Variables;
    package OS renames GNAT.OS_Lib;
    use Ada.Strings.Unbounded;
    use type OS.String_Access;

    Failed : exception;

    RTS    : constant String := "obj/gnatcov-rts";
    Traces : constant String := "obj/traces";
    Scope  : constant String := "-P template_tests.gpr --projects=template --level=stmt+decision";

    --  Runs Program (absolute or relative path) with space-separated Args; raises Failed on a
    --  non-zero exit status.
    procedure Spawn (Program, Args : String) is
        List : OS.Argument_List_Access := OS.Argument_String_To_List (Args);
        Code : constant Integer := OS.Spawn (Program, List.all);
    begin
        OS.Free (List);
        if Code /= 0 then
            raise Failed with Program & " exited with status" & Code'Image;
        end if;
    end Spawn;

    --  Same as Spawn, for a tool looked up on PATH (alr run puts the crate's tools there).
    procedure Run (Tool, Args : String) is
        Path : OS.String_Access := OS.Locate_Exec_On_Path (Tool);
    begin
        if Path = null then
            raise Failed with Tool & " not found on PATH";
        end if;
        declare
            Program : constant String := Path.all;
        begin
            OS.Free (Path);
            Spawn (Program, Args);
        end;
    end Run;

    procedure Remove (Dir : String) is
    begin
        if Dirs.Exists (Dir) then
            Dirs.Delete_Tree (Dir);
        end if;
    end Remove;

    function Trace_Files return String is
        Result : Unbounded_String;
        Search : Dirs.Search_Type;
        Item   : Dirs.Directory_Entry_Type;
    begin
        Dirs.Start_Search (Search, Traces, "*.srctrace");
        while Dirs.More_Entries (Search) loop
            Dirs.Get_Next_Entry (Search, Item);
            Append (Result, " " & Traces & "/" & Dirs.Simple_Name (Item));
        end loop;
        Dirs.End_Search (Search);
        return To_String (Result);
    end Trace_Files;

    function Read (Path : String) return String is
        File   : Ada.Text_IO.File_Type;
        Result : Unbounded_String;
    begin
        Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
        while not Ada.Text_IO.End_Of_File (File) loop
            Append (Result, Ada.Text_IO.Get_Line (File) & " ");
        end loop;
        Ada.Text_IO.Close (File);
        return To_String (Result);
    end Read;

    --  Value of the first Name="<natural>" attribute in Text (the Cobertura root element).
    function Attribute (Text, Name : String) return Natural is
        Key   : constant String := Name & "=""";
        First : constant Natural := Ada.Strings.Fixed.Index (Text, Key);
    begin
        if First = 0 then
            raise Failed with "no " & Name & " in the Cobertura report";
        end if;
        declare
            From : constant Positive := First + Key'Length;
            Last : constant Natural := Ada.Strings.Fixed.Index (Text, """", From);
        begin
            return Natural'Value (Text (From .. Last - 1));
        end;
    end Attribute;

    function Trim (S : String) return String
    is (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

    function Image (Value : Float) return String is
        Buffer : String (1 .. 16);
    begin
        Ada.Float_Text_IO.Put (Buffer, Value, Aft => 2, Exp => 0);
        return Trim (Buffer) & "%";
    end Image;

    Min : constant Float :=
        (if CL.Argument_Count >= 1 then Float'Value (CL.Argument (1)) else 80.0);
begin
    if not Dirs.Exists (RTS) then
        Run ("gnatcov", "setup --prefix=" & RTS);
    end if;
    Env.Set
        ("GPR_PROJECT_PATH",
         Dirs.Full_Name (RTS)
         & "/share/gpr"
         & (if Env.Exists ("GPR_PROJECT_PATH") then ":" & Env.Value ("GPR_PROJECT_PATH") else ""));

    Run ("gnatcov", "instrument " & Scope);
    Run
        ("gprbuild",
         "-q -P template_tests.gpr --src-subdirs=gnatcov-instr --implicit-with=gnatcov_rts"
         & " tests_main.adb");

    Remove (Traces);
    Remove ("obj/coverage");
    Remove ("obj/cobertura");
    Dirs.Create_Path (Traces);
    Env.Set ("GNATCOV_TRACE_FILE", Traces & "/");
    Spawn ("bin/tests_main", "");
    Env.Clear ("GNATCOV_TRACE_FILE");

    declare
        Report : constant String :=
            "coverage " & Scope & " --excluded-source-files=template.adb" & Trace_Files;
    begin
        Run ("gnatcov", Report & " --annotate=report");
        Run ("gnatcov", Report & " --annotate=xcov+ --output-dir=obj/coverage");
        Run ("gnatcov", Report & " --annotate=cobertura --output-dir=obj/cobertura");
    end;

    declare
        Xml     : constant String := Read ("obj/cobertura/cobertura.xml");
        Covered : constant Natural := Attribute (Xml, "lines-covered");
        Valid   : constant Natural := Attribute (Xml, "lines-valid");
        Percent : constant Float :=
            (if Valid = 0 then 100.0 else 100.0 * Float (Covered) / Float (Valid));
    begin
        Ada.Text_IO.Put_Line
            ("line coverage "
             & Image (Percent)
             & " ("
             & Trim (Covered'Image)
             & "/"
             & Trim (Valid'Image)
             & ", min "
             & Image (Min)
             & ")");
        if Percent < Min then
            raise Failed with "coverage below " & Image (Min);
        end if;
    end;
exception
    when E : Failed =>
        Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Ada.Exceptions.Exception_Message (E));
        CL.Set_Exit_Status (CL.Failure);
end Coverage;

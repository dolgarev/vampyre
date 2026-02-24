with Ada.Strings.Fixed;
with Ada.Strings;
with Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package body Renderer is

   -------------------------------------------------------------------------
   procedure Initialize_Colors is
   begin
      Start_Color;
      Init_Pair (Color_Pair (1), Red,     Black);  --  Walls
      Init_Pair (Color_Pair (2), Green,   Black);  --  Blocks
      Init_Pair (Color_Pair (3), Cyan,    Black);  --  Player (@)
      Init_Pair (Color_Pair (4), Magenta, Black);  --  Vampire
      Init_Pair (Color_Pair (5), Yellow,  Black);  --  Status bar
      Init_Pair (Color_Pair (6), Red,     Black);  --  Dead player / alert
   end Initialize_Colors;

   -------------------------------------------------------------------------
   --  Helper: print Text centred on Win at absolute row Row
   procedure Center_Text
     (Win : Window; Row : Line_Position; Text : String) is
      L : Line_Count;
      C : Column_Count;
   begin
      Get_Size (Win, L, C);
      declare
         Col : constant Column_Position :=
           Column_Position ((Integer (C) - Text'Length) / 2);
      begin
         Move_Cursor (Win, Row, Col);
         Add (Win, Text);
      end;
   end Center_Text;

   -------------------------------------------------------------------------
   procedure Draw_Game (State : Game_State) is
      Win : constant Window := Standard_Window;
      L   : Line_Count;
      C   : Column_Count;

      --  Layout: 1 status row + Max_Rows map rows = Max_Rows + 1 total rows
      --          Max_Cols columns
      L_Off : Line_Position;
      C_Off : Column_Position;

      Ticks_Per_Sec : constant Integer := 1000 / Settings.Game_Tick_Ms;
      Seconds_Left  : constant Integer :=
        State.Ticks_Remaining / Ticks_Per_Sec;

      --  Right-justify Val in a field of Width characters
      function Pad (Val : Integer; Width : Positive := 3) return String is
         use Ada.Strings.Fixed;
         use Ada.Strings;
         S : constant String := Trim (Val'Image, Both);
      begin
         if S'Length < Width then
            return [1 .. Width - S'Length => ' '] & S;
         else
            return S;
         end if;
      end Pad;

   begin
      Get_Size (Win, L, C);

      --  Centre the field (map + 1 status line) vertically and horizontally.
      --  Total height needed = Max_Rows + 1; total width = Max_Cols.
      L_Off := Line_Position (Integer (L) - (Max_Rows + 1)) / 2;
      C_Off := Column_Position (Integer (C) - Max_Cols) / 2;
      if L_Off < 0 then L_Off := 0; end if;
      if C_Off < 0 then C_Off := 0; end if;

      Erase (Win);

      --  --- Draw map ---
      for R in 1 .. Max_Rows loop
         for Col in 1 .. Max_Cols loop
            Move_Cursor (Win,
                         L_Off + Line_Position (R - 1),
                         C_Off + Column_Position (Col - 1));
            case State.Map (R, Col) is
               when Wall =>
                  Set_Character_Attributes (Win, Color => Color_Pair (1));
                  Add (Win, Settings.Char_Wall);

               when Block =>
                  Set_Character_Attributes (Win, Color => Color_Pair (2));
                  Add (Win, Settings.Char_Block);

               when Player =>
                  Set_Character_Attributes (Win, Color => Color_Pair (3));
                  Add (Win, Settings.Char_Player);

               when Vampire =>
                  declare
                     Is_Blink : Boolean := False;
                  begin
                     for I in 1 .. State.Num_Vampires loop
                        if State.Vampires (I).Alive and then
                           State.Vampires (I).Row = R and then
                           State.Vampires (I).Col = Col
                        then
                           if State.Vampires (I).Trapped then
                              Is_Blink := (State.Ticks_Remaining / 2 mod 2 = 0);
                           end if;
                           exit;
                        end if;
                     end loop;

                     if not Is_Blink then
                        Set_Character_Attributes (Win, Color => Color_Pair (4));
                        Add (Win, Settings.Char_Vampire);
                     else
                        Add (Win, ' ');
                     end if;
                  end;

               when Space =>
                  Add (Win, ' ');
            end case;
         end loop;
      end loop;

      --  --- Death Animation Overlay ---
      if State.Player_Dead then
         Move_Cursor (Win,
                      L_Off + Line_Position (State.Player_Row - 1),
                      C_Off + Column_Position (State.Player_Col - 1));
         if (State.Death_Timer mod 4) < 2 then
            Set_Character_Attributes
              (Win,
               Attr  => (Blink => True, others => False),
               Color => Color_Pair (6));
            Add (Win, Settings.Char_Dead);
         else
            Set_Character_Attributes (Win, Color => Color_Pair (3));
            Add (Win, Settings.Char_Player);
         end if;
      end if;

      --  --- Status bar (row directly below the map) ---
      declare
         Time_Part : constant String :=
           (if Settings.Timer_Enabled
            then "  TIME:" & Pad (Seconds_Left, 4) & "s"
            else "");
         Bar : constant String :=
           " LEVEL:" & Pad (State.Level, 2) &
           "  STEPS:" & Pad (State.Steps, 5) &
           Time_Part &
           "  LIVES:" & Pad (State.Lives, 2) &
           "  VAMPIRES:" & Pad (State.Alive_Vampires, 2) &
           "/" & Pad (State.Num_Vampires, 2) & " ";
         Bar_Len : constant Integer := Integer'Min (Bar'Length, Max_Cols);
         Pad_Len : constant Integer := (Max_Cols - Bar_Len) / 2;
         S       : String (1 .. Max_Cols) := [others => ' '];
      begin
         --  Place the centred string into S
         S (Pad_Len + 1 .. Pad_Len + Bar_Len) :=
           Bar (Bar'First .. Bar'First + Bar_Len - 1);

         Move_Cursor (Win,
                      L_Off + Line_Position (Max_Rows),
                      C_Off);
         Set_Character_Attributes (Win, Color => Color_Pair (5));
         Add (Win, S);
      end;

      Refresh (Win);
   end Draw_Game;

   -------------------------------------------------------------------------
   procedure Show_Splash is
      Win : constant Window := Standard_Window;
      L   : Line_Count;
      C   : Column_Count;
      Row : Line_Position;
   begin
      Get_Size (Win, L, C);
      Row := Line_Position (Integer (L) / 2 - 8);
      if Row < 0 then Row := 0; end if;
      Erase (Win);

      Set_Character_Attributes (Win, Color => Color_Pair (4));
      Center_Text (Win, Row + 0, " __   __ _    __  __ ____  ___ ___ ___ ");
      Center_Text (Win, Row + 1, " \ \ / // \  |  \/  |  _ \|_ _| _ \ __|");
      Center_Text (Win, Row + 2, "  \ V // _ \ | |\/| | |_) || ||   / _| ");
      Center_Text (Win, Row + 3, "   \_//_/ \_\|_|  |_|  __/|___|_|_\___|");
      Center_Text (Win, Row + 4, "               Vampyre |_|              ");

      Set_Character_Attributes (Win, Color => Color_Pair (5));
      Center_Text (Win, Row + 6, "A free implementation of the Agat-7 game Vampir (1987)");

      Set_Character_Attributes (Win, Color => Color_Pair (3));
      Center_Text (Win, Row + 8,  "CONTROLS:");
      Center_Text (Win, Row + 9,  "  Arrow keys  - move the hero (@)");
      Center_Text (Win, Row + 10, "  Push blocks (W) to trap vampires (V)");
      Center_Text (Win, Row + 11, "  Chains of blocks can be pushed at once");

      Set_Character_Attributes (Win, Color => Color_Pair (2));
      Center_Text (Win, Row + 13, "GOAL: surround every vampire with blocks!");

      Set_Character_Attributes (Win, Color => Color_Pair (5));
      Center_Text (Win, Row + 15, "R - restart level     Q - quit");

      Set_Character_Attributes (Win, Color => Color_Pair (1));
      Center_Text (Win, Row + 17, ">>>  Press any key to start  <<<");

      Refresh (Win);
   end Show_Splash;

   -------------------------------------------------------------------------
   procedure Show_Level_Complete (State : Game_State) is
      Win : constant Window := Standard_Window;
      L   : Line_Count;
      C   : Column_Count;
      Row : Line_Position;
   begin
      Get_Size (Win, L, C);
      Row := Line_Position (Integer (L) / 2 - 3);
      if Row < 0 then Row := 0; end if;
      Erase (Win);

      Set_Character_Attributes (Win, Color => Color_Pair (2));
      Center_Text (Win, Row, "  L E V E L   C L E A R E D  ");

      Set_Character_Attributes (Win, Color => Color_Pair (3));
      Center_Text (Win, Row + 2,
                   "Level: " & Integer'Image (State.Level) &
                   "     Steps taken: " & Integer'Image (State.Steps));

      Set_Character_Attributes (Win, Color => Color_Pair (5));
      if State.Level < Settings.Max_Levels then
         Center_Text (Win, Row + 5, "R - next level     Q - quit");
      else
         Set_Character_Attributes (Win, Color => Color_Pair (4));
         Center_Text (Win, Row + 4, "All levels cleared!  Outstanding!");
         Set_Character_Attributes (Win, Color => Color_Pair (5));
         Center_Text (Win, Row + 6, "R - play again     Q - quit");
      end if;

      Refresh (Win);
   end Show_Level_Complete;

   -------------------------------------------------------------------------
   procedure Show_Game_Over (State : Game_State) is
      Win : constant Window := Standard_Window;
      L   : Line_Count;
      C   : Column_Count;
      Row : Line_Position;
   begin
      Get_Size (Win, L, C);
      Row := Line_Position (Integer (L) / 2 - 3);
      if Row < 0 then Row := 0; end if;
      Erase (Win);

      Set_Character_Attributes (Win, Color => Color_Pair (6));
      Center_Text (Win, Row, "  G A M E   O V E R  ");

      Set_Character_Attributes (Win, Color => Color_Pair (3));
      Center_Text (Win, Row + 2,
                   "Level reached: " & Integer'Image (State.Level) &
                   "     Steps: " & Integer'Image (State.Steps));

      Set_Character_Attributes (Win, Color => Color_Pair (5));
      Center_Text (Win, Row + 5, "R - new game     Q - quit");

      Refresh (Win);
   end Show_Game_Over;

   -------------------------------------------------------------------------
   procedure Show_Victory (State : Game_State) is
      Win : constant Window := Standard_Window;
      L   : Line_Count;
      C   : Column_Count;
      Row : Line_Position;
   begin
      Get_Size (Win, L, C);
      Row := Line_Position (Integer (L) / 2 - 4);
      if Row < 0 then Row := 0; end if;
      Erase (Win);

      Set_Character_Attributes (Win, Color => Color_Pair (4));
      Center_Text (Win, Row,     "  Y O U   W I N !  ");
      Center_Text (Win, Row + 1, "  All vampires have been destroyed!  ");

      Set_Character_Attributes (Win, Color => Color_Pair (2));
      Center_Text (Win, Row + 3, "All " & Integer'Image (Settings.Max_Levels) &
                                 " levels completed!");

      Set_Character_Attributes (Win, Color => Color_Pair (3));
      Center_Text (Win, Row + 5,
                   "Total steps: " & Integer'Image (State.Steps));

      Set_Character_Attributes (Win, Color => Color_Pair (5));
      Center_Text (Win, Row + 8, "R - play again     Q - quit");

      Refresh (Win);
   end Show_Victory;

end Renderer;

with Settings;
with Ada.Numerics.Discrete_Random;

package body Engine is

   --  Random number generation for level generation
   package Rand_Int is new Ada.Numerics.Discrete_Random (Integer);
   Gen : Rand_Int.Generator;

   --  Directions array for 8-directional vampire movement
   type Dir_Offset is record DR, DC : Integer; end record;
   Dirs_8 : constant array (1 .. 8) of Dir_Offset :=
     ((-1, -1), (-1, 0), (-1, 1),
      ( 0, -1),          ( 0, 1),
      ( 1, -1), ( 1, 0), ( 1, 1));

   ---------------------------------------------------------------------------
   --  Is_Trapped
   ---------------------------------------------------------------------------
   function Is_Trapped
     (State : Game_State; VR, VC : Integer) return Boolean
   is
   begin
      for D of Dirs_8 loop
         declare
            NR : constant Integer := VR + D.DR;
            NC : constant Integer := VC + D.DC;
         begin
            if NR in 1 .. Max_Rows and then NC in 1 .. Max_Cols then
               if State.Map (NR, NC) = Space or else
                  State.Map (NR, NC) = Player
               then
                  return False;  --  at least one escape route exists
               end if;
            end if;
         end;
      end loop;
      return True;  --  no escape routes
   end Is_Trapped;

   ---------------------------------------------------------------------------
   --  Push_Chain
   ---------------------------------------------------------------------------
   function Push_Chain
     (State : in out Game_State; Row, Col, DR, DC : Integer) return Boolean
   is
      NR : constant Integer := Row + DR;
      NC : constant Integer := Col + DC;
   begin
      --  Out of bounds → cannot push
      if NR not in 1 .. Max_Rows or else NC not in 1 .. Max_Cols then
         return False;
      end if;

      case State.Map (NR, NC) is
         when Space =>
            --  Target cell is free — move the block there
            State.Map (NR, NC) := Block;
            State.Map (Row, Col) := Space;
            return True;

         when Block =>
            --  Recursively try to push the next block in the chain
            if Push_Chain (State, NR, NC, DR, DC) then
               State.Map (NR, NC) := Block;
               State.Map (Row, Col) := Space;
               return True;
            else
               return False;
            end if;

         when Vampire =>
            return False;

         when Wall | Player =>
            return False;
      end case;
   end Push_Chain;

   ---------------------------------------------------------------------------
   --  Init_Level
   ---------------------------------------------------------------------------
   procedure Init_Level (State : out Game_State; Level : Integer) is
      Num_Vamps  : constant Integer :=
        Settings.Vampires_Start + Level - 1;
      Num_Blocks : constant Integer :=
        Settings.Blocks_Start - (Level - 1) * Settings.Blocks_Step;

      Placed     : Integer;
      R, C       : Integer;
   begin
      Rand_Int.Reset (Gen);

      --  Default-initialise
      State := (Map             => (others => (others => Space)),
                Player_Row      => (Max_Rows + 1) / 2,
                Player_Col      => (Max_Cols + 1) / 2,
                Vampires        => (others => (0, 0, False)),
                Num_Vampires    => Num_Vamps,
                Alive_Vampires  => Num_Vamps,
                Steps           => 0,
                Vampire_Ticker  => 0,
                Lives           => Settings.Start_Lives,
                Level           => Level,
                Ticks_Remaining =>
                  Settings.Level_Time_Sec *
                  (1000 / Settings.Game_Tick_Ms),
                Player_Dead     => False,
                Death_Timer     => 0,
                Game_Over       => False,
                Level_Complete  => False);

      --  Draw border walls
      for R2 in 1 .. Max_Rows loop
         State.Map (R2, 1)        := Wall;
         State.Map (R2, Max_Cols) := Wall;
      end loop;
      for C2 in 1 .. Max_Cols loop
         State.Map (1, C2)        := Wall;
         State.Map (Max_Rows, C2) := Wall;
      end loop;

      --  Place player
      State.Map (State.Player_Row, State.Player_Col) := Player;

      --  Place vampires near corners
      declare
         Corner_Positions : constant array (1 .. 4) of Dir_Offset :=
           ((2, 2), (2, Max_Cols - 1), (Max_Rows - 1, 2),
            (Max_Rows - 1, Max_Cols - 1));
      begin
         for I in 1 .. Num_Vamps loop
            declare
               CP : constant Dir_Offset :=
                 Corner_Positions (((I - 1) mod 4) + 1);
               VR : Integer := CP.DR;
               VC : Integer := CP.DC;
            begin
               --  Shift slightly if corner already used (>4 vampires)
               if I > 4 then
                  VR := VR + (I / 4) * 2;
                  VC := VC + (I / 4) * 2;
               end if;
               --  Clamp to valid inner area
               if VR < 2 then VR := 2; end if;
               if VR > Max_Rows - 1 then VR := Max_Rows - 1; end if;
               if VC < 2 then VC := 2; end if;
               if VC > Max_Cols - 1 then VC := Max_Cols - 1; end if;

               State.Vampires (I) := (Row => VR, Col => VC, Alive => True);
               State.Map (VR, VC) := Vampire;
            end;
         end loop;
      end;

      --  Scatter blocks randomly (avoid player, vampires, walls)
      Placed := 0;
      while Placed < Num_Blocks loop
         R := (abs (Rand_Int.Random (Gen)) mod (Max_Rows - 4)) + 3;
         C := (abs (Rand_Int.Random (Gen)) mod (Max_Cols - 4)) + 3;
         if State.Map (R, C) = Space then
            --  Keep a small clear area around the player (3×3)
            if abs (R - State.Player_Row) > 1 or else
               abs (C - State.Player_Col) > 1
            then
               State.Map (R, C) := Block;
               Placed := Placed + 1;
            end if;
         end if;
      end loop;
   end Init_Level;

   ---------------------------------------------------------------------------
   --  Move_Player
   ---------------------------------------------------------------------------
   procedure Move_Player (State : in out Game_State; DR, DC : Integer) is
      NR : constant Integer := State.Player_Row + DR;
      NC : constant Integer := State.Player_Col + DC;
   begin
      if State.Player_Dead or State.Game_Over or State.Level_Complete then
         return;
      end if;

      if NR not in 1 .. Max_Rows or else NC not in 1 .. Max_Cols then
         return;
      end if;

      case State.Map (NR, NC) is
         when Wall =>
            null;  --  cannot enter wall

         when Block =>
            --  Try to push the block chain
            if Push_Chain (State, NR, NC, DR, DC) then
               --  Block pushed successfully — move player
               State.Map (State.Player_Row, State.Player_Col) := Space;
               State.Player_Row := NR;
               State.Player_Col := NC;
               State.Map (NR, NC) := Player;
               State.Steps := State.Steps + 1;
               State.Vampire_Ticker := State.Vampire_Ticker + 1;
               if State.Vampire_Ticker >= Settings.Vampire_Speed then
                  State.Vampire_Ticker := 0;
                  Update_Vampires (State);
               end if;
            end if;

         when Space =>
            State.Map (State.Player_Row, State.Player_Col) := Space;
            State.Player_Row := NR;
            State.Player_Col := NC;
            State.Map (NR, NC) := Player;
            State.Steps := State.Steps + 1;
            State.Vampire_Ticker := State.Vampire_Ticker + 1;
            if State.Vampire_Ticker >= Settings.Vampire_Speed then
               State.Vampire_Ticker := 0;
               Update_Vampires (State);
            end if;

         when Vampire =>
            --  Player walks into a vampire — die
            State.Player_Dead := True;
            State.Death_Timer := 20;  --  20 ticks death animation
            State.Steps := State.Steps + 1;

         when Player =>
            null;  --  should never happen
      end case;

      --  Check win: all vampires dead
      if State.Alive_Vampires = 0 then
         State.Level_Complete := True;
      end if;
   end Move_Player;

   ---------------------------------------------------------------------------
   --  Update_Vampires
   ---------------------------------------------------------------------------
   procedure Update_Vampires (State : in out Game_State) is

      --  Chebyshev-minimising step toward (PR, PC) from (VR, VC)
      function Best_Step (VR, VC : Integer) return Dir_Offset is
         Best      : Dir_Offset := (0, 0);
         Best_Dist : Integer := Integer'Last;
         Dist      : Integer;
         NR, NC    : Integer;
      begin
         for D of Dirs_8 loop
            NR := VR + D.DR;
            NC := VC + D.DC;
            if NR in 1 .. Max_Rows and then NC in 1 .. Max_Cols then
               if State.Map (NR, NC) = Space or else
                  State.Map (NR, NC) = Player
               then
                  Dist := Integer'Max
                    (abs (NR - State.Player_Row),
                     abs (NC - State.Player_Col));
                  if Dist < Best_Dist then
                     Best_Dist := Dist;
                     Best      := D;
                  end if;
               end if;
            end if;
         end loop;
         return Best;
      end Best_Step;

   begin
      if State.Player_Dead or State.Game_Over or State.Level_Complete then
         return;
      end if;

      for I in 1 .. State.Num_Vampires loop
         if State.Vampires (I).Alive then
            declare
               VR   : Integer renames State.Vampires (I).Row;
               VC   : Integer renames State.Vampires (I).Col;
               Step : constant Dir_Offset := Best_Step (VR, VC);
               NR   : constant Integer    := VR + Step.DR;
               NC   : constant Integer    := VC + Step.DC;
            begin
               if Step.DR /= 0 or else Step.DC /= 0 then
                  if State.Map (NR, NC) = Player then
                     --  Vampire reaches the player — player dies
                     State.Map (VR, VC) := Space;
                     VR := NR;
                     VC := NC;
                     State.Map (NR, NC) := Vampire;
                     State.Player_Dead  := True;
                     State.Death_Timer  := 20;
                  else
                     State.Map (VR, VC) := Space;
                     VR := NR;
                     VC := NC;
                     State.Map (NR, NC) := Vampire;
                  end if;
               end if;

               --  After moving, check if now trapped
               if Is_Trapped (State, VR, VC) then
                  State.Map (VR, VC) := Space;
                  State.Vampires (I).Alive := False;
                  State.Alive_Vampires := State.Alive_Vampires - 1;
               end if;
            end;
         end if;
      end loop;

      --  Win check
      if State.Alive_Vampires = 0 then
         State.Level_Complete := True;
      end if;
   end Update_Vampires;

   ---------------------------------------------------------------------------
   --  Tick
   ---------------------------------------------------------------------------
   procedure Tick (State : in out Game_State) is
   begin
      --  Death animation countdown
      if State.Player_Dead then
         State.Death_Timer := State.Death_Timer - 1;
         if State.Death_Timer <= 0 then
            State.Player_Dead := False;
            State.Lives := State.Lives - 1;
            if State.Lives <= 0 then
               State.Game_Over := True;
            end if;
         end if;
         return;
      end if;

      if State.Game_Over or State.Level_Complete then
         return;
      end if;

      --  Level timer countdown (only when enabled in Settings)
      if Settings.Timer_Enabled then
         State.Ticks_Remaining := State.Ticks_Remaining - 1;
         if State.Ticks_Remaining <= 0 then
            --  Time's up — lose a life and restart the level
            State.Player_Dead := True;
            State.Death_Timer := 20;
         end if;
      end if;
   end Tick;

end Engine;

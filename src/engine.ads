with Settings;

package Engine is

   Max_Rows : constant := Settings.Map_Rows + 2;  --  includes border walls
   Max_Cols : constant := Settings.Map_Cols + 2;

   type Entity_Type is
     (Space, Wall, Block, Player, Vampire);

   type Map_Data is
     array (1 .. Max_Rows, 1 .. Max_Cols) of Entity_Type;

   --  Per-vampire record: position and alive flag
   type Vampire_Record is record
      Row   : Integer := 0;
      Col   : Integer := 0;
      Alive : Boolean := False;
   end record;

   type Vampire_Array is
     array (1 .. Settings.Max_Vampires) of Vampire_Record;

   type Game_State is record
      Map              : Map_Data;
      Player_Row       : Integer;
      Player_Col       : Integer;
      Vampires         : Vampire_Array;
      Num_Vampires     : Integer;        --  total on this level
      Alive_Vampires   : Integer;        --  still alive
      Steps            : Integer;        --  hero step counter
      Vampire_Ticker   : Integer;        --  counts steps to next vampire move
      Lives            : Integer;
      Level            : Integer;
      Ticks_Remaining  : Integer;        --  countdown ticks for level timer
      Player_Dead      : Boolean;        --  currently in death animation
      Death_Timer      : Integer;
      Game_Over        : Boolean;
      Level_Complete   : Boolean;
   end record;

   --  Initialise state for a given level (1..Max_Levels)
   procedure Init_Level (State : out Game_State; Level : Integer);

   --  Attempt to move the hero by (DR, DC). Handles block pushing.
   --  DR/DC must be in {-1, 0, 1} with exactly one non-zero (4 directions).
   procedure Move_Player (State : in out Game_State; DR, DC : Integer);

   --  Advance all living vampires one step toward the player.
   --  Called by the main loop every Vampire_Speed hero steps.
   procedure Update_Vampires (State : in out Game_State);

   --  One game-clock tick: decrement level timer, handle death animation.
   procedure Tick (State : in out Game_State);

private

   --  Returns True if the vampire at (VR, VC) is completely surrounded
   --  (cannot move in any of the 8 directions).
   function Is_Trapped
     (State : Game_State; VR, VC : Integer) return Boolean;

   --  Try to push a chain of blocks starting at (Row, Col) in direction (DR, DC).
   --  Returns True and modifies the map if the push succeeds.
   function Push_Chain
     (State : in out Game_State; Row, Col, DR, DC : Integer) return Boolean;

end Engine;

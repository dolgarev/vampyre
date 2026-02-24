package Settings is

   --  === Display ===
   --  Game field dimensions (inner area, excluding border walls)
   Map_Rows : constant := 20;
   Map_Cols : constant := 78;

   --  === Display Characters ===
   Char_Wall    : constant Character := '0';
   Char_Block   : constant Character := 'W';
   Char_Player  : constant Character := '@';
   Char_Vampire : constant Character := 'V';
   Char_Dead    : constant Character := 'X';

   --  === Timing ===
   --  Duration of one main game loop iteration (milliseconds)
   Game_Tick_Ms : constant := 100;

   --  Set to True to enable a per-level time limit; False = no timer
   Timer_Enabled : constant Boolean := False;

   --  Number of seconds allowed per level (only used when Timer_Enabled)
   Level_Time_Sec : constant := 120;

   --  === Player ===
   Start_Lives : constant := 3;

   --  Each hero step increments the step counter.
   --  Vampires move once every Vampire_Speed hero steps.
   Vampire_Speed : constant := 5;

   --  === Day/Night Cycle ===
   Cycle_Length : constant := 12;  --  Steps per phase
   Vampire_Speed_Day   : constant := 4;  --  Moves every 4 steps
   Vampire_Speed_Night : constant := 2;  --  Moves every 2 steps

   --  === Levels ===
   Max_Levels : constant := 10;

   --  Number of vampires on level N = Vampires_Start + (N - 1)
   Vampires_Start : constant := 2;

   --  Number of blocks on level N = Blocks_Start - (N - 1) * Blocks_Step
   --  Must be enough to trap all vampires (~4 blocks per vampire minimum).
   Blocks_Start : constant := 60;
   Blocks_Step  : constant := 2;

   --  Upper bound for vampire array sizing
   Max_Vampires : constant := Vampires_Start + Max_Levels - 1;

end Settings;

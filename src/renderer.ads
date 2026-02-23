with Engine; use Engine;

package Renderer is

   --  Initialise ncurses colour pairs
   procedure Initialize_Colors;

   --  Draw the full game screen (map + status bar)
   procedure Draw_Game (State : Game_State);

   --  Full-screen splash / title screen
   procedure Show_Splash;

   --  Shown when a level is completed
   procedure Show_Level_Complete (State : Game_State);

   --  Shown when all lives are lost
   procedure Show_Game_Over (State : Game_State);

   --  Shown when all 8 levels are beaten
   procedure Show_Victory (State : Game_State);

end Renderer;

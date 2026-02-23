with Engine;   use Engine;
with Renderer; use Renderer;
with Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

procedure Main is
   State   : Game_State;
   Key     : Key_Code;
   Win     : Window;
   Cur_Vis : Cursor_Visibility := Invisible;

   Initial_State : Game_State;
   Restart_Level : Boolean;
   Current_Level : Integer;
   Was_Dead      : Boolean;
begin
   --  ncurses setup
   Init_Screen;
   Win := Standard_Window;
   Renderer.Initialize_Colors;
   Set_Echo_Mode (False);
   Set_KeyPad_Mode (Win, True);
   Set_Cursor_Visibility (Cur_Vis);

   --  Splash screen (blocking)
   Renderer.Show_Splash;
   Set_Timeout_Mode (Win, Blocking, 0);
   Key := Get_Keystroke (Win);

   --  ============================================================
   --  Outer loop: iterate through all levels
   --  ============================================================
   Current_Level := 1;
   Outer_Loop :
   loop
      exit Outer_Loop when Current_Level > Settings.Max_Levels;

      Engine.Init_Level (State, Current_Level);
      State.Lives := (if Current_Level = 1 then Settings.Start_Lives
                      else State.Lives);
      Initial_State := State;

      --  Set timed input: Game_Tick_Ms per iteration
      Set_Timeout_Mode (Win, Delayed, Settings.Game_Tick_Ms);

      Restart_Level := False;

      --  ============================================================
      --  Play loop for this level
      --  ============================================================
      Play_Loop :
      loop
         Renderer.Draw_Game (State);

         Key := Get_Keystroke (Win);

         --  Handle keyboard
         case Key is
            when Key_Cursor_Up    => Engine.Move_Player (State, -1,  0);
            when Key_Cursor_Down  => Engine.Move_Player (State,  1,  0);
            when Key_Cursor_Left  => Engine.Move_Player (State,  0, -1);
            when Key_Cursor_Right => Engine.Move_Player (State,  0,  1);
            when Character'Pos ('r') | Character'Pos ('R') =>
               Restart_Level := True;
               exit Play_Loop;
            when Character'Pos ('q') | Character'Pos ('Q') =>
               exit Outer_Loop;
            when others =>
               null;
         end case;

         --  Clock tick: timer countdown + death animation
         Was_Dead := State.Player_Dead;
         Engine.Tick (State);

         --  Death after animation: lose a life, restart or game over
         if State.Game_Over then
            exit Play_Loop;
         end if;

         --  After death animation, reset the level exactly as it was
         if Was_Dead and then not State.Player_Dead then
            declare
               Saved_Lives : constant Integer := State.Lives;
            begin
               State := Initial_State;
               State.Lives := Saved_Lives;
            end;
         end if;

         exit Play_Loop when State.Level_Complete;
      end loop Play_Loop;

      if Restart_Level then
         --  Soft restart: same level, exact initial state, keep lives
         declare
            Saved_Lives : constant Integer := State.Lives;
         begin
            State := Initial_State;
            State.Lives := Saved_Lives;
         end;

      elsif State.Game_Over then
         --  Show game over screen, wait for input
         Set_Timeout_Mode (Win, Blocking, 0);
         Renderer.Show_Game_Over (State);
         Wait_GO :
         loop
            Key := Get_Keystroke (Win);
            case Key is
               when Character'Pos ('r') | Character'Pos ('R') =>
                  Current_Level := 1;
                  exit Wait_GO;
               when Character'Pos ('q') | Character'Pos ('Q') =>
                  exit Outer_Loop;
               when others => null;
            end case;
         end loop Wait_GO;

      elsif State.Level_Complete then
         Set_Timeout_Mode (Win, Blocking, 0);
         if Current_Level = Settings.Max_Levels then
            Renderer.Show_Victory (State);
         else
            Renderer.Show_Level_Complete (State);
         end if;
         Wait_LC :
         loop
            Key := Get_Keystroke (Win);
            case Key is
               when Character'Pos ('r') | Character'Pos ('R') =>
                  if Current_Level = Settings.Max_Levels then
                     Current_Level := 1;
                  else
                     Current_Level := Current_Level + 1;
                  end if;
                  exit Wait_LC;
               when Character'Pos ('q') | Character'Pos ('Q') =>
                  exit Outer_Loop;
               when others => null;
            end case;
         end loop Wait_LC;
      end if;

   end loop Outer_Loop;

   End_Screen;
end Main;

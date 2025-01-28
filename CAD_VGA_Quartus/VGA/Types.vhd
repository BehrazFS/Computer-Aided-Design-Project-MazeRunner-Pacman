LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE MazeTypes IS
    TYPE Node IS ARRAY (3 DOWNTO 0) OF STD_LOGIC;
    TYPE Maze IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF Node;
	 TYPE GameState IS (WAIT_FOR_START, PLAYING, POTION_GEN,  REGENERATE, WIN, LOSE_WITH_LIVE, LOSE_WITH_TIME, OUTER_GAME);
    TYPE StackObj is
        record
            i : integer range 0 to 8;
            j : integer range 0 to 8;
            validMoves : std_logic_vector(3 downto 0); -- index 0 up, index 1 down, index 2 right, index 3 left
        end record;
    TYPE MapGenerateState IS (NOT_INIT, GENERATING, END_GENERATE, dummy);
END MazeTypes;
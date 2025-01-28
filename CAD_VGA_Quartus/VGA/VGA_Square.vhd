LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.MazeTypes.ALL;

ENTITY Maze_Game IS

	PORT (
		CLK_50MHz : IN STD_LOGIC;
		RESET : IN STD_LOGIC;
		ColorOut : OUT STD_LOGIC_VECTOR(11 DOWNTO 0); -- RED & GREEN & BLUE
		SQUAREWIDTH : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		ScanlineX : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		ScanlineY : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		key : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		-- New Game
		end_game : IN BIT;
		score : OUT INTEGER;
		lose : OUT BIT;
		isStarted : OUT STD_LOGIC;
		HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
	);
END Maze_Game;

ARCHITECTURE Behavioral OF Maze_Game IS

	SIGNAL ColorOutput, ColorOutput2 : STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL ex, ey : INTEGER RANGE -1024 TO 1023;
	CONSTANT BLOCK_SIZE : POSITIVE := 50;
	CONSTANT WALL_SIZE : POSITIVE := 8;
	CONSTANT MAP_SIZE : POSITIVE := 9;
	CONSTANT entity_initial_Size : POSITIVE := wall_size * 2;
	SIGNAL entitySize : POSITIVE;
	SIGNAL entitycolor : STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL positionx, positiony : INTEGER := 0;
	SIGNAL mazeOut : Maze (MAP_SIZE - 1 DOWNTO 0, MAP_SIZE - 1 DOWNTO 0);
	SIGNAL COUNTER, Conuter50Mil, Counter25Mil : INTEGER;
	SIGNAL CLK_40HZ, CLK_1HZ, CLK_2HZ : STD_LOGIC;
	SIGNAL MyGameState : GameState;
	SIGNAL lives : INTEGER RANGE 0 TO 5;
	SIGNAL gcount : INTEGER RANGE -1 TO 9;
	SIGNAL gClkCounter : INTEGER;
	SIGNAL mazeState : MapGenerateState;
	SIGNAL unitCounter, tensCounter : INTEGER RANGE 0 TO 9;
	SIGNAL reachEnd : STD_LOGIC;
	SIGNAL pGenEnd : STD_LOGIC;
	SIGNAL showSegCounter : INTEGER RANGE 0 TO 7;
	SIGNAL LIFE_EN, SET : STD_LOGIC;
	SIGNAL randomNum : INTEGER RANGE 0 TO 8;
	SIGNAL pseudoRand : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL p_speed_x, p_speed_y, p_ghost_x, p_ghost_y, p_map_x, p_map_y, p_size_x, p_size_y, p_rand_x, p_rand_y : INTEGER;
	SIGNAL ghostEn, resizeEn, mapEn, speedEn : STD_LOGIC;
	CONSTANT potionSize : POSITIVE := 16;
	SIGNAL entitydirection : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL enemyX, enemyY : INTEGER RANGE -1024 TO 1023;
	SIGNAL enemyNextDir : INTEGER RANGE 0 TO 3;
	SIGNAL enemyDir : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL hitEnemy : STD_LOGIC;
	SIGNAL randEn : STD_LOGIC;
	SIGNAL randTimerCounter : INTEGER RANGE 1 TO 3;
	SIGNAL randCounter : INTEGER;
	SIGNAL checkNext : STD_LOGIC;
	SIGNAL IsOutGame : STD_LOGIC;


	signal hue       : integer range 0 to 360;  -- Hue value (0 to 360 degrees)
    signal red       : integer range 0 to 15;   -- 4-bit red channel
    signal green     : integer range 0 to 15;   -- 4-bit green channel
    signal blue      : integer range 0 to 15;   -- 4-bit blue channel
    signal scaled_y  : integer;                -- Scaled Y position (0 to 360)
	signal scaled_x  : integer;                -- Scaled X position (0 to 360)



    constant COLOR_SKY     : std_logic_vector(11 downto 0) := "001101111111"; -- Light blue
    constant COLOR_GRASS   : std_logic_vector(11 downto 0) := "000011110000"; -- Green
    constant COLOR_SUN     : std_logic_vector(11 downto 0) := "111111110000"; -- Yellow
    constant COLOR_CAT     : std_logic_vector(11 downto 0) := "100100010001"; -- Brown (Cat fur)
    constant COLOR_CAT_EYE : std_logic_vector(11 downto 0) := "111111111111"; -- White
    constant COLOR_TREE     : std_logic_vector(11 downto 0) := "011010100001"; -- Brown (Tree trunk)
    constant COLOR_LEAVES   : std_logic_vector(11 downto 0) := "000110110000"; -- Dark green (Tree leaves)
	 
	-- New Game Part 
	SIGNAL CLK_24MHz : STD_LOGIC;
	SIGNAL SquareX : STD_LOGIC_VECTOR(9 DOWNTO 0) := "1111111111";
	SIGNAL SquareY : STD_LOGIC_VECTOR(9 DOWNTO 0) := "1111111111";
	SIGNAL SquareXMoveDir, SquareYMoveDir : STD_LOGIC := '0';
	--constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
	CONSTANT SquareXmin : STD_LOGIC_VECTOR(9 DOWNTO 0) := "0000000001";
	SIGNAL SquareXmax : STD_LOGIC_VECTOR(9 DOWNTO 0); -- := "1010000000"-SquareWidth;
	CONSTANT SquareYmin : STD_LOGIC_VECTOR(9 DOWNTO 0) := "0000000001";
	SIGNAL SquareYmax : STD_LOGIC_VECTOR(9 DOWNTO 0); -- := "0111100000"-SquareWidth;
	SIGNAL ColorSelect : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
	SIGNAL Prescaler : STD_LOGIC_VECTOR(30 DOWNTO 0);
	--location of wall first
	SIGNAL wallX1 : STD_LOGIC_VECTOR(9 DOWNTO 0) := "1111111111";
	SIGNAL wallY1 : STD_LOGIC_VECTOR(9 DOWNTO 0) := "1111111111";
	--location of wall second
	SIGNAL wallX2 : STD_LOGIC_VECTOR(9 DOWNTO 0) := "1111111111";
	SIGNAL wallY2 : STD_LOGIC_VECTOR(9 DOWNTO 0) := "1111111111";
	--use in random function 
	SIGNAL pseudo_rand : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL p_rand1 : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL p_rand2 : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL score_signal : INTEGER RANGE 0 TO 11 := 0;

	COMPONENT mazegen
		GENERIC (
			BLOCK_SIZE : POSITIVE := 50;
			WALL_SIZE : POSITIVE := 20;
			MAP_SIZE : POSITIVE := 9);
		PORT (
			clk : IN STD_LOGIC;
			reset : IN STD_LOGIC;
			regenEn : IN STD_LOGIC;
			mazeOut : OUT Maze (MAP_SIZE - 1 DOWNTO 0, MAP_SIZE - 1 DOWNTO 0);
			mazeState : OUT MapGenerateState
		);
	END COMPONENT;

	IMPURE FUNCTION gen_map(i : INTEGER;j : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;
	BEGIN
		x := i / BLOCK_SIZE;
		y := j / BLOCK_SIZE;

		IF ex <= i AND i < ex + entitysize AND j >= ey AND j < ey + entitysize THEN
			RETURN "1111";
		END IF;

		IF enemyX <= i AND i < enemyX + entity_initial_Size AND j >= enemyY AND j < enemyY + entity_initial_Size THEN
			RETURN "1110";
		END IF;
		IF (p_speed_x <= i AND i < p_speed_x + potionSize) AND (j >= p_speed_y AND j < p_speed_y + potionSize) AND speedEn = '0'THEN
			RETURN "1001";
		END IF;
		IF (p_ghost_x <= i AND i < p_ghost_x + potionSize) AND (j >= p_ghost_y AND j < p_ghost_y + potionSize) AND ghostEn = '0' THEN
			RETURN "1010";
		END IF;
		IF (p_map_x <= i AND i < p_map_x + potionSize) AND (j >= p_map_y AND j < p_map_y + potionSize) AND mapEn = '0'THEN
			RETURN "1011";
		END IF;
		IF (p_size_x <= i AND i < p_size_x + potionSize) AND (j >= p_size_y AND j < p_size_y + potionSize) AND resizeEn = '0' THEN
			RETURN "1100";
		END IF;

		IF ((j MOD BLOCK_SIZE < WALL_SIZE)) THEN
			IF (mazeout(x, y)(3) = '0') THEN
				RETURN "0010";
			END IF;
		END IF;
		IF ((j MOD BLOCK_SIZE > BLOCK_SIZE - WALL_SIZE)) THEN
			IF (mazeout(x, y)(2) = '0') THEN
				RETURN "0100";
			END IF;
		END IF;
		IF ((i MOD BLOCK_SIZE < WALL_SIZE)) THEN
			IF (mazeout(x, y)(0) = '0') THEN
				RETURN "0000";
			END IF;
		END IF;
		IF ((i MOD BLOCK_SIZE > BLOCK_SIZE - WALL_SIZE)) THEN
			IF (mazeout(x, y)(1) = '0') THEN
				RETURN "0001";
			END IF;
		END IF;
		IF (((i MOD BLOCK_SIZE < WALL_SIZE) OR (i MOD BLOCK_SIZE > BLOCK_SIZE - WALL_SIZE)) AND ((j MOD BLOCK_SIZE < WALL_SIZE) OR (j MOD BLOCK_SIZE > BLOCK_SIZE - WALL_SIZE))) THEN
			RETURN "0110";
		END IF;
		RETURN "1000";
	END gen_map;

	CONSTANT speed_cube : STD_LOGIC_VECTOR(0 TO potionSize * potionSize - 1) :=
	"1111111111111111" & -- ****************
	"1000000000000001" & -- *              *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000000000001" & -- *              *
	"1000000000000001" & -- *              *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000000000001" & -- *              *
	"1000000000000001" & -- *              *
	"1111111111111111"; -- ****************

	CONSTANT map_cube : STD_LOGIC_VECTOR(0 TO potionSize * potionSize - 1) :=
	"1111111111111111" & -- ****************
	"1000000000000001" & -- *              *
	"1000011111100001" & -- *    ******    *
	"1000110000110001" & -- *   **    **   *
	"1000110000110001" & -- *   **    **   *
	"1000000001100001" & -- *        **    *
	"1000000011000001" & -- *       **     *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000000000001" & -- *              *
	"1000000000000001" & -- *              *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000000000001" & -- *              *
	"1111111111111111"; -- ****************

	CONSTANT ghost_cube : STD_LOGIC_VECTOR(0 TO potionSize * potionSize - 1) :=
	"1111111111111111" & -- ****************
	"1000000000000001" & -- *              *
	"1000000000000001" & -- *              *
	"1000000000011101" & -- *          *** *
	"1000000000111001" & -- *         ***  *
	"1000000001110001" & -- *        ***   *
	"1000000011100001" & -- *       ***    *
	"1000000111000001" & -- *      ***     *
	"1000001110000001" & -- *     ***      *
	"1000011100000001" & -- *    ***       *
	"1000111000000001" & -- *   ***        *
	"1001110000000001" & -- *  ***         *
	"1011100000000001" & -- * ***          *
	"1000000000000001" & -- *              *
	"1000000000000001" & -- *              *
	"1111111111111111"; -- ****************

	CONSTANT resize_cube : STD_LOGIC_VECTOR(0 TO potionSize * potionSize - 1) :=
	"1111111111111111" & -- ****************
	"1000000000000001" & -- *              *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1011111111111101" & -- * ************ *
	"1011111111111101" & -- * ************ *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000110000001" & -- *      **      *
	"1000000000000001" & -- *              *
	"1111111111111111"; -- ****************

	CONSTANT enemy_two_leg_cube : STD_LOGIC_VECTOR(0 TO entity_initial_Size * entity_initial_Size - 1) :=
	"0000000000000000" & --     ******** 
	"0011111111111100" & --   ************ 
	"0111111111111110" & --  **************
	"1111111111111111" & -- ****************
	"1111100011000111" & -- *****   **   ***
	"1111100011000111" & -- *****   **   ***
	"1111111111111111" & -- ****************
	"1111111111111111" & -- ****************
	"1111111111111111" & -- ****************
	"1111111111111111" & -- ****************
	"1111111001111111" & -- ******    ******
	"1111110000111111" & -- *****      *****
	"1111100000011111" & -- ****        ****
	"1111000000001111" & -- ***          ***
	"1111000000001111" & -- ***          ***
	"1111000000001111"; --  ***          ***

	CONSTANT enemy_one_leg_cube : STD_LOGIC_VECTOR(0 TO entity_initial_Size * entity_initial_Size - 1) :=
	"0000000000000000" & --     ******** 
	"0011111111111100" & --   ************ 
	"0111111111111110" & --  **************
	"1111111111111111" & -- ****************
	"1111100011000111" & -- *****   **   ***
	"1111100011000111" & -- *****   **   ***
	"1111111111111111" & -- ****************
	"1111111111111111" & -- ****************
	"1111111111111111" & -- ****************
	"1111111111111111" & -- ****************
	"1111111111111111" & --     ********    
	"0111001111001110" & --      ****** 
	"0111000110001110" & --       ****
	"0111000110001110" & --        **
	"0111000110001110" & --        ** 
	"0000000000000000"; --         **    

	CONSTANT entity_cube : STD_LOGIC_VECTOR(0 TO entity_initial_Size * entity_initial_Size - 1) :=
	"0000011111110000" & --     ****     
	"0000111111111000" & --    *****    
	"0001100011111100" & --   *******   
	"0011100011111110" & --  **  ****  
	"0111111111110000" & -- ***  ****  
	"0111111111100000" & -- *******    
	"1111111111000000" & -- ******     
	"1111111110000000" & -- *****      
	"1111111110000000" & -- *****      
	"1111111111000000" & -- ******     
	"0111111111100000" & -- *******    
	"0111111111110000" & -- *********  
	"0011111111111110" & --  ********  
	"0001111111111100" & --   *******   
	"0000111111111000" & --    *****    
	"0000011111110000"; --     **** 
	CONSTANT entity_cube_dead : STD_LOGIC_VECTOR(0 TO entity_initial_Size * entity_initial_Size - 1) :=
	"0000011111110000" & --     ****     
	"0000111111111000" & --    *****    
	"0001111111111100" & --   *******   
	"0011101011010110" & --  ********  
	"0111110111101110" & -- *********  
	"0111101011010110" & -- *********    
	"1111111111111110" & -- *********     
	"1111111111111110" & -- *********      
	"1111111111111110" & -- *********      
	"1111111111111110" & -- *********     
	"0111111111111110" & -- *********    
	"0111111111111110" & -- *********  
	"0011111111111110" & --  ********  
	"0001111111111100" & --   *******   
	"0000111111111000" & --    *****    
	"0000011111110000"; --     **** 
	CONSTANT entity_cube_closed : STD_LOGIC_VECTOR(0 TO entity_initial_Size * entity_initial_Size - 1) :=
	"0000011111110000" & --     ****     
	"0000111111111000" & --    *****    
	"0001111111111100" & --   *******   
	"0011111111111110" & --  ********  
	"0111111111111110" & -- *********  
	"0111111111111110" & -- *********    
	"1111111111111110" & -- *********     
	"1111111111111110" & -- *********      
	"1111111111111110" & -- *********      
	"1111111111111110" & -- *********     
	"0111111111111110" & -- *********    
	"0111111111111110" & -- *********  
	"0011111111111110" & --  ********  
	"0001111111111100" & --   *******   
	"0000111111111000" & --    *****    
	"0000011111110000"; --     **** 

	CONSTANT entity_cube_small : STD_LOGIC_VECTOR(0 TO (entity_initial_Size/2) * (entity_initial_Size/2) - 1) :=
	"00111100" & --   ****   
	"01001110" & --  ******  
	"11001100" & -- *******
	"11111000" & -- *******   
	"11111000" & -- *******   
	"11111100" & -- ******* 
	"01111110" & --  ******  
	"00111100"; --   ****   

	CONSTANT entity_cube_small_closed : STD_LOGIC_VECTOR(0 TO (entity_initial_Size/2) * (entity_initial_Size/2) - 1) :=
	"00111100" & --   ****   
	"01111110" & --  ******  
	"11111110" & -- ** ***
	"11111110" & -- *****   
	"11111110" & -- *****   
	"11111110" & -- ****** 
	"01111110" & --  ******  
	"00111100"; --   ****    

	IMPURE FUNCTION speed_shape(i : INTEGER;j : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;

	BEGIN

		x := (i - p_speed_x);
		y := (j - p_speed_y);
		IF speed_cube(y * potionSize + x) = '1' THEN
			RETURN "011100011010";
		ELSE
			RETURN "000000000000";
		END IF;

	END speed_shape;

	IMPURE FUNCTION ghost_shape(i : INTEGER;j : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;

	BEGIN

		x := (i - p_ghost_x);
		y := (j - p_ghost_y);
		IF ghost_cube(y * potionSize + x) = '1' THEN
			RETURN "000010010000";
		ELSE
			RETURN "000000000000";
		END IF;

	END ghost_shape;

	IMPURE FUNCTION resize_shape(i : INTEGER;j : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;

	BEGIN

		x := (i - p_size_x);
		y := (j - p_size_y);
		IF resize_cube(y * potionSize + x) = '1' THEN
			RETURN "111110000001";
		ELSE
			RETURN "000000000000";
		END IF;

	END resize_shape;
	IMPURE FUNCTION enemy_shape(i : INTEGER;j : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;

	BEGIN

		x := (i - enemyX);
		y := (j - enemyY);
		IF (CLK_2HZ = '1') THEN
			IF enemy_two_leg_cube(y * entity_initial_Size + x) = '1' THEN
				RETURN "111100000000";
			ELSE
				RETURN "000000000000";
			END IF;
		ELSE
			IF enemy_one_leg_cube(y * entity_initial_Size + x) = '1' THEN
				RETURN "111100000000";
			ELSE
				RETURN "000000000000";
			END IF;
		END IF;

	END enemy_shape;
	IMPURE FUNCTION map_shape(i : INTEGER;j : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;

	BEGIN

		x := (i - p_map_x);
		y := (j - p_map_y);
		IF map_cube(y * potionSize + x) = '1' THEN
			RETURN "110111110011";
		ELSE
			RETURN "000000000000";
		END IF;

	END map_shape;
	IMPURE FUNCTION entity_shape(i : INTEGER;j : INTEGER; color : STD_LOGIC_VECTOR;direction : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
		VARIABLE x, y : INTEGER;
		VARIABLE ecolor : STD_LOGIC_VECTOR(11 DOWNTO 0);
		VARIABLE xy : INTEGER;
	BEGIN
		ecolor := color;
		x := (i - ex);
		y := (j - ey);
		IF direction = "00" THEN -- right
			xy := (y * entitySize + x - 1);
		ELSIF direction = "01" THEN -- left
			xy := (y * entitySize + (entitySize - x - 1));
		ELSIF direction = "10" THEN --up
			xy := (x * entitySize + (entitySize - y - 1));
		ELSIF direction = "11" THEN --down
			xy := (x * entitySize + y - 1);
		ELSE
			xy := (y * entitySize + x - 1);
		END IF;
		IF resizeEn = '0' THEN
			IF (CLK_2HZ = '1') THEN
				IF entity_cube(xy) = '1' THEN
					RETURN ecolor;
				ELSE
					RETURN "000000000000";
				END IF;
			ELSE
				IF entity_cube_closed(xy) = '1' THEN
					RETURN ecolor;
				ELSE
					RETURN "000000000000";
				END IF;
			END IF;
		ELSE
			IF (MyGameState = LOSE_WITH_LIVE OR MyGameState = LOSE_WITH_TIME) THEN
				IF entity_cube_dead(xy) = '1' THEN
					RETURN ecolor;
				ELSE
					RETURN "000000000000";
				END IF;
			ELSIF (CLK_2HZ = '1') THEN
				IF entity_cube_small(xy) = '1' THEN
					RETURN ecolor;
				ELSE
					RETURN "000000000000";
				END IF;
			ELSE
				IF entity_cube_small_closed(xy) = '1' THEN
					RETURN ecolor;
				ELSE
					RETURN "000000000000";
				END IF;
			END IF;
		END IF;
	END entity_shape;

	FUNCTION convSEG (N : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
		VARIABLE ans : STD_LOGIC_VECTOR(6 DOWNTO 0);
	BEGIN
		CASE N IS
			WHEN "0000" => ans := "1000000";
			WHEN "0001" => ans := "1111001";
			WHEN "0010" => ans := "0100100";
			WHEN "0011" => ans := "0110000";
			WHEN "0100" => ans := "0011001";
			WHEN "0101" => ans := "0010010";
			WHEN "0110" => ans := "0000010";
			WHEN "0111" => ans := "1111000";
			WHEN "1000" => ans := "0000000";
			WHEN "1001" => ans := "0010000";
			WHEN "1010" => ans := "0001000";
			WHEN "1011" => ans := "0000011";
			WHEN "1100" => ans := "1000110";
			WHEN "1101" => ans := "0100001";
			WHEN "1110" => ans := "0000110";
			WHEN "1111" => ans := "0001110";
			WHEN OTHERS => ans := "1111111";
		END CASE;
		RETURN ans;
	END FUNCTION convSEG;

	IMPURE FUNCTION Is_Next_Move_Wall(key : STD_LOGIC_VECTOR; ex : INTEGER; ey : INTEGER; Size : INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE nextX, nextY : STD_LOGIC_VECTOR(3 DOWNTO 0);
	BEGIN
		IF (key(0) = '1') THEN
			nextX := gen_map(ex, ey - 1);
			nextY := gen_map(ex + size, ey - 1);
		ELSIF (key(1) = '1') THEN
			nextX := gen_map(ex, ey + size + 1);
			nextY := gen_map(ex + size, ey + size + 1);
		ELSIF (key(2) = '1') THEN
			nextX := gen_map(ex + size + 1, ey);
			nextY := gen_map(ex + size + 1, ey + size);
		ELSIF (key(3) = '1') THEN
			nextX := gen_map(ex - 1, ey);
			nextY := gen_map(ex - 1, ey + size);
		END IF;
		IF nextX(3) = '0' OR nextY(3) = '0' THEN
			RETURN "111";
		ELSIF nextX /= "1000" THEN
			RETURN nextX(2 DOWNTO 0);
		ELSIF nexty /= "1000" THEN
			RETURN nexty(2 DOWNTO 0);
		ELSE
			RETURN "000";
		END IF;
	END Is_Next_Move_Wall;

	FUNCTION getEnemyMove(rand : INTEGER) RETURN STD_LOGIC_VECTOR IS
	BEGIN
		IF (rand = 0) THEN
			RETURN "0001";
		ELSIF (rand = 1) THEN
			RETURN "0010";
		ELSIF (rand = 2) THEN
			RETURN "0100";
		ELSIF (rand = 3) THEN
			RETURN "1000";
		END IF;
		RETURN "0001";
	END FUNCTION getEnemyMove;

BEGIN

	UUT : mazegen
	GENERIC MAP(
		BLOCK_SIZE => BLOCK_SIZE,
		WALL_SIZE => WALL_SIZE,
		MAP_SIZE => MAP_SIZE
	)
	PORT MAP(
		clk => CLK_50MHz,
		reset => reset,
		regenEn => mapEn,
		mazeout => mazeout,
		mazeState => mazeState
	);

	PROCESS (CLK_50MHz)
		FUNCTION lfsr32(x : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
		BEGIN
			RETURN x(30 DOWNTO 0) & (x(0) XNOR x(1) XNOR x(21) XNOR x(31));
		END FUNCTION;
	BEGIN
		IF rising_edge(CLK_50MHz) THEN
			pseudoRand <= lfsr32(pseudoRand);
			randomNum <= to_integer(unsigned(pseudoRand(3 DOWNTO 0))) MOD 9;
			enemyNextDir <= to_integer(unsigned(pseudoRand)) MOD 4;
		END IF;
	END PROCESS;

	POTION_PROCESS : PROCESS (CLK_50MHz, RESET)
		VARIABLE loc : INTEGER;
	BEGIN
		IF RESET = '1' THEN
			p_speed_x <= - 1;
			p_speed_y <= - 1;
			p_ghost_x <= - 1;
			p_ghost_y <= - 1;
			p_map_x <= - 1;
			p_map_y <= - 1;
			p_size_x <= - 1;
			p_size_y <= - 1;
			pGenEnd <= '0';
		ELSIF CLK_50MHz'EVENT AND CLK_50MHz = '1' THEN
			loc := randomNum * BLOCK_SIZE + (BLOCK_SIZE/2) - (potionSize/2);
			IF p_speed_x =- 1 THEN
				p_speed_x <= loc;
			ELSIF p_speed_y =- 1 THEN
				IF NOT (loc = p_speed_x AND loc = (BLOCK_SIZE/2) - (potionSize/2)) THEN
					p_speed_y <= loc;
				END IF;
			ELSIF p_ghost_x =- 1 THEN
				p_ghost_x <= loc;
			ELSIF p_ghost_y =- 1 THEN
				IF NOT (loc = p_speed_y AND p_ghost_x = p_speed_x) AND NOT (loc = p_ghost_x AND loc = (BLOCK_SIZE/2) - (potionSize/2)) THEN
					p_ghost_y <= loc;
				END IF;
			ELSIF p_map_x =- 1 THEN
				p_map_x <= loc;
			ELSIF p_map_y =- 1 THEN
				IF NOT (loc = p_ghost_y AND p_map_x = p_ghost_x) AND NOT (loc = p_speed_y AND p_map_x = p_speed_x) AND NOT (loc = p_map_x AND loc = (BLOCK_SIZE/2) - (potionSize/2)) THEN
					p_map_y <= loc;
				END IF;
			ELSIF p_size_x =- 1 THEN
				p_size_x <= loc;
			ELSIF p_size_y =- 1 THEN
				IF NOT (loc = p_map_y AND p_size_x = p_map_x) AND NOT (loc = p_ghost_y AND p_size_x = p_ghost_x) AND NOT (loc = p_speed_y AND p_size_x = p_speed_x) AND NOT (loc = p_size_x AND loc = (BLOCK_SIZE/2) - (potionSize/2)) THEN
					p_size_y <= loc;
					pGenEnd <= '1';
				END IF;
			ELSIF p_rand_x = -1 THEN
				p_rand_x <= loc;
			ELSIF p_rand_y = -1 THEN
				IF NOT (loc = p_map_y AND p_rand_x = p_map_x)  AND NOT (loc = p_size_y AND p_rand_x = p_size_x) AND NOT (loc = p_ghost_y AND p_rand_x = p_ghost_x) AND NOT (loc = p_speed_y AND p_rand_x = p_speed_x) AND NOT (loc = p_rand_x AND loc = (BLOCK_SIZE/2) - (potionSize/2)) THEN
					p_rand_y <= loc;
					pGenEnd <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS;

	Main_Game_Process : PROCESS (CLK_50MHz, RESET)
	BEGIN
		IF (RESET = '1') THEN
			MyGameState <= POTION_GEN;
		ELSIF (CLK_50MHz'EVENT AND CLK_50MHz = '1') THEN
			IF (MyGameState = POTION_GEN) THEN
				IF (pGenEnd = '1') THEN
					MyGameState <= WAIT_FOR_START;
				END IF;
			ELSIF (MyGameState = WAIT_FOR_START) THEN
				IF (mazeState = END_GENERATE) THEN
					-- TODO : add a key for regenerate map (Optional) !!
					IF (key(0) = '1' OR key(1) = '1' OR key(2) = '1' OR key(3) = '1') THEN
						MyGameState <= PLAYING;
					END IF;
				END IF;
			ELSIF (MyGameState = PLAYING) THEN
				IF (lives = 0 OR hitEnemy = '1') THEN
					MyGameState <= LOSE_WITH_LIVE;
				ELSIF (unitCounter = 0 AND tensCounter = 0) THEN
					MyGameState <= LOSE_WITH_TIME;
				ELSIF (reachEnd = '1') THEN
					MyGameState <= WIN;
				END IF;
				IF (IsOutGame = '1') THEN
					MyGameState <= OUTER_GAME;
				END IF;
			END IF;
		END IF;
	END PROCESS Main_Game_Process;

	Move_Enemy_Process : PROCESS (CLK_40Hz, reset)
		VARIABLE enemy_move : STD_LOGIC_VECTOR(2 DOWNTO 0);
		VARIABLE canMove : STD_LOGIC;
	BEGIN
		IF (reset = '1') THEN
			enemyX <= BLOCK_SIZE * MAP_SIZE - Wall_Size - entity_initial_Size - 5;
			enemyY <= BLOCK_SIZE * MAP_SIZE - Wall_Size - entity_initial_Size - 5;
			enemyDir <= "0001";
			randTimerCounter <= 1;
			randCounter <= 0;
			randEn <= '0';
			checkNext <= '0';
		ELSIF (rising_edge(CLK_40Hz)) THEN
			enemy_move := Is_Next_Move_Wall(enemyDir, enemyX, enemyY, entity_initial_Size);
			canMove := '1';
			IF (randEn = '0') THEN
				IF (randTimerCounter * randCounter = 180) THEN
					randCounter <= 0;
					randTimerCounter <= ((randTimerCounter + 1) MOD 3) + 1;
					randEn <= '1';
				ELSE
					randCounter <= randCounter + 1;
				END IF;
			ELSE
				canMove := '0';
				IF (checkNext = '0') THEN
					enemyDir <= getEnemyMove(enemyNextDir);
					checkNext <= '1';
				ELSE
					IF (enemy_move /= "111") THEN
						randEn <= '0';
						checkNext <= '0';
						canMove := '1';
					ELSE
						enemyDir <= getEnemyMove(enemyNextDir);
					END IF;
				END IF;
			END IF;
			IF (enemy_move /= "111" AND canMove = '1') THEN
				IF enemyDir(0) = '1' THEN -- UP
					IF (enemyY /= 0) THEN
						enemyY <= enemyY - 1;
					ELSE
						enemyDir <= getEnemyMove(enemyNextDir);
					END IF;
				ELSIF enemyDir(1) = '1' THEN --DOWN
					enemyY <= enemyY + 1;
				ELSIF enemyDir(2) = '1' THEN --RIGHT
					IF (enemyX + entity_initial_Size + 1 < MAP_SIZE * BLOCK_SIZE - 1) THEN
						enemyX <= enemyX + 1;
					ELSE
						enemyDir <= getEnemyMove(enemyNextDir);
					END IF;
				ELSIF enemyDir(3) = '1' THEN --LEFT
					enemyX <= enemyX - 1;
				END IF;
			ELSIF (enemy_move = "111" AND canMove = '1') THEN
				enemyDir <= getEnemyMove(enemyNextDir);
			END IF;
		END IF;
	END PROCESS;

	Move_Entity_Process : PROCESS (CLK_40Hz, reset)
		VARIABLE next_move : STD_LOGIC_VECTOR(2 DOWNTO 0);
	BEGIN
		IF (reset = '1') THEN
			ex <= Wall_Size + 5;
			ey <= Wall_Size + 5;
			lives <= 5;
			reachEnd <= '0';
			ghostEn <= '0';
			resizeEn <= '0';
			mapEn <= '0';
			speedEn <= '0';
			entitydirection <= "00";
			IsOutGame <= '0';
		ELSIF (rising_edge(CLK_40Hz)) THEN
			SET <= '0';
			next_move := Is_Next_Move_Wall(key, ex, ey, entitysize);
			reachEnd <= reachEnd;
			IF (next_move /= "111" AND MyGameState = PLAYING) THEN
				IF next_move = "001" THEN -- speed
					speedEn <= '1';
				END IF;
				IF next_move = "010" THEN -- ghost
					ghostEn <= '1';
				END IF;
				IF next_move = "011" THEN -- map
					mapEn <= '1';
				END IF;
				IF next_move = "100" THEN -- size
					resizeEn <= '1';
				END IF;
				IF KEY(0) = '1' THEN -- UP
					entitydirection <= "10";
					IF (EY /= 0) THEN
						EY <= EY - 1;
					ELSIF (EY = 0) THEN
						IsOutGame <= '1';
					END IF;
				ELSIF KEY(1) = '1' THEN --DOWN
					entitydirection <= "11";
					EY <= EY + 1;
				ELSIF KEY(2) = '1' THEN --RIGHT
					entitydirection <= "00";
					EX <= EX + 1;
					IF (EX + 1 > MAP_SIZE * BLOCK_SIZE - 1) THEN
						reachEnd <= '1';
					END IF;
				ELSIF KEY(3) = '1' THEN --LEFT
					entitydirection <= "01";
					EX <= EX - 1;
				END IF;
			ELSIF (next_move = "111" AND MyGameState = PLAYING AND key /= "0000" AND LIFE_EN = '1' AND (ghostEn = '0' OR gcount <= 0)) THEN
				lives <= lives - 1;
				SET <= '1';
			END IF;
		END IF;
	END PROCESS Move_Entity_Process;

	PROCESS (ex, ey, enemyX, enemyY)
	BEGIN
		IF (ex + entitySize > enemyX AND ex < enemyX + entitySize AND
			ey + entitySize > enemyY AND ey < enemyY + entitySize) THEN
			hitEnemy <= '1';
		ELSE
			hitEnemy <= '0';
		END IF;
	END PROCESS;

	entitySize <= wall_size * 2 WHEN resizeEn = '0' ELSE
		wall_size;

	PROCESS (CLK_2HZ, RESET, SET)
	BEGIN
		IF (reset = '1') THEN
			LIFE_EN <= '1';
			IF (ghostEn = '0' OR gcount <= 0) THEN
				entitycolor <= "111111110000";
			ELSE
				entitycolor <= "000010011111";
			END IF;
		ELSIF (SET = '1') THEN
			entitycolor <= "111110010000";
			LIFE_EN <= '0';
		ELSIF (CLK_2HZ'EVENT AND CLK_2HZ = '1') THEN
			LIFE_EN <= '1';
			IF (ghostEn = '0' OR gcount <= 0) THEN
				entitycolor <= "111111110000";
			ELSE
				entitycolor <= "000010011111";
			END IF;
		END IF;
	END PROCESS;

	Timer_Process : PROCESS (CLK_1HZ, RESET)
	BEGIN
		IF (RESET = '1') THEN
			unitCounter <= 9;
			tensCounter <= 9;
		ELSIF (CLK_1HZ'EVENT AND CLK_1HZ = '1') THEN
			IF (MyGameState = PLAYING) THEN
				IF (unitCounter = 0 AND tensCounter > 0) THEN
					unitCounter <= 9;
					tensCounter <= tensCounter - 1;
				ELSIF (unitCounter > 0) THEN
					unitCounter <= unitCounter - 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (CLK_2HZ, RESET)
	BEGIN
		IF (RESET = '1') THEN
			showSegCounter <= 0;
		ELSIF (CLK_2HZ'EVENT AND CLK_2HZ = '1') THEN
			IF (showSegCounter = 7) THEN
				showSegCounter <= 0;
			ELSE
				showSegCounter <= showSegCounter + 1;
			END IF;
		END IF;
	END PROCESS;

	SEG_Display_Process : PROCESS (MyGameState, showSegCounter, CLK_2HZ)
	BEGIN
		IF (MyGameState /= OUTER_GAME) THEN
			HEX0 <= "1111111";
			HEX1 <= "1111111";
			HEX2 <= "1111111";
			HEX3 <= "1111111";
			HEX4 <= "1111111";
			HEX5 <= "1111111";
			IF (ghostEn = '1' AND gcount >= 0) THEN
				HEX5 <= convSEG(STD_LOGIC_VECTOR(TO_UNSIGNED(gcount, 4)));
			END IF;
			IF (MyGameState = WAIT_FOR_START AND CLK_2HZ = '1') THEN
				HEX0 <= convSEG("0000");
				HEX1 <= convSEG("0011");
				HEX4 <= convSEG("0011");
				HEX5 <= convSEG("0101");
			ELSIF (MyGameState = PLAYING) THEN
				HEX0 <= convSEG(STD_LOGIC_VECTOR(TO_UNSIGNED(unitCounter, 4)));
				HEX1 <= convSEG(STD_LOGIC_VECTOR(TO_UNSIGNED(tensCounter, 4)));
			ELSIF (MyGameState = WIN AND CLK_2HZ = '1') THEN
				IF (showSegCounter >= 4) THEN
					HEX0 <= "1000110";
				END IF;
				IF (showSegCounter >= 3) THEN
					HEX1 <= "1000110";
				END IF;
				IF (showSegCounter >= 2) THEN
					HEX2 <= "1000001";
				END IF;
				IF (showSegCounter >= 1) THEN
					HEX3 <= "0010010";
				END IF;
			ELSIF (MyGameState = LOSE_WITH_LIVE AND CLK_2HZ = '1') THEN
				IF (showSegCounter >= 4) THEN
					HEX0 <= "0000110";
				END IF;
				IF (showSegCounter >= 3) THEN
					HEX1 <= "0010010";
				END IF;
				IF (showSegCounter >= 2) THEN
					HEX2 <= "1000000";
				END IF;
				IF (showSegCounter >= 1) THEN
					HEX3 <= "1000111";
				END IF;
			ELSIF (MyGameState = LOSE_WITH_TIME AND CLK_2HZ = '1') THEN
				IF (showSegCounter >= 4) THEN
					HEX0 <= "0000110";
				END IF;
				IF (showSegCounter >= 3) THEN
					HEX1 <= "0010010";
				END IF;
				IF (showSegCounter >= 2) THEN
					HEX2 <= "1000000";
				END IF;
				IF (showSegCounter >= 1) THEN
					HEX3 <= "1000111";
				END IF;
			END IF;
		ELSE
			HEX0 <= "ZZZZZZZ";
			HEX1 <= "ZZZZZZZ";
			HEX2 <= "ZZZZZZZ";
			HEX3 <= "ZZZZZZZ";
			HEX4 <= "ZZZZZZZ";
			HEX5 <= "ZZZZZZZ";
		END IF;
	END PROCESS;
	PROCESS (CLK_50MHz, RESET)
	BEGIN
		IF (ghostEn = '0') THEN
			gcount <= 9;
			gClkCounter <= 0;
		ELSIF (CLK_50MHz'EVENT AND CLK_50MHz = '1') THEN
			IF (gClkCounter >= 50000000) THEN
				gClkCounter <= 0;
				IF gcount =- 1 THEN
					NULL;
				ELSE
					gcount <= gcount - 1;
				END IF;
			ELSE
				gClkCounter <= gClkCounter + 1;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (CLK_50MHz, reset)
	BEGIN
		IF (reset = '1') THEN
			Conuter50Mil <= 0;
			CLK_1HZ <= '0';
		ELSIF (rising_edge(CLK_50MHz)) THEN
			IF (Conuter50Mil >= 25000000) THEN
				Conuter50Mil <= 0;
				CLK_1HZ <= NOT CLK_1HZ;
			ELSE
				Conuter50Mil <= Conuter50Mil + 1;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (CLK_50MHz, reset)
	BEGIN
		IF (reset = '1') THEN
			Counter25Mil <= 0;
			CLK_2HZ <= '0';
		ELSIF (rising_edge(CLK_50MHz)) THEN
			IF (Counter25Mil >= 25000000) THEN
				Counter25Mil <= 0;
				CLK_2HZ <= NOT CLK_2HZ;
			ELSE
				Counter25Mil <= Counter25Mil + 1;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (clk_50mhz, reset)
	BEGIN
		IF (reset = '1') THEN
			COUNTER <= 0;
			CLK_40HZ <= '0';
		ELSIF (rising_edge(CLK_50MHz)) THEN
			IF ((counter >= 625000 AND speedEn = '0') OR ((counter >= 312500 AND speedEn = '1'))) THEN
				COUNTER <= 0;
				cLK_40HZ <= NOT CLK_40HZ;
			ELSE
				Counter <= Counter + 1;
			END IF;
		END IF;
	END PROCESS;

	PROCESS (clk_50mhz, reset)
	BEGIN
		IF (reset = '1') THEN
			CLK_24MHz <= '0';
		ELSIF (rising_edge(CLK_50MHz)) THEN
			CLK_24MHz <= NOT CLK_24MHz;
		END IF;
	END PROCESS;

	ConvertLivesToLEDProcess : PROCESS (lives)
	BEGIN
		IF (lives = 5) THEN
			LEDR(4 DOWNTO 0) <= "11111";
		ELSIF (lives = 4) THEN
			LEDR(4 DOWNTO 0) <= "11110";
		ELSIF (lives = 3) THEN
			LEDR(4 DOWNTO 0) <= "11100";
		ELSIF (lives = 2) THEN
			LEDR(4 DOWNTO 0) <= "11000";
		ELSIF (lives = 1) THEN
			LEDR(4 DOWNTO 0) <= "10000";
		ELSIF (lives = 0) THEN
			LEDR(4 DOWNTO 0) <= "00000";
		ELSE
			LEDR(4 DOWNTO 0) <= "11111";
		END IF;
	END PROCESS ConvertLivesToLEDProcess;
	-- New Game Part 

	PROCESS (CLK_24MHz, IsOutGame)
		-- maximal length 32-bit xnor LFSR
		FUNCTION lfsr32(x : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
		BEGIN
			RETURN x(30 DOWNTO 0) & (x(0) XNOR x(1) XNOR x(21) XNOR x(31));
		END FUNCTION;
		VARIABLE flag_rst : BIT := '0';
		VARIABLE flag_wall1 : BIT := '0';
		VARIABLE flag_wall2 : BIT := '0';
	BEGIN
		IF IsOutGame = '0' THEN
			pseudo_rand <= lfsr32(pseudo_rand);
			p_rand1 <= "00" & pseudo_rand(7 DOWNTO 0);
			p_rand2 <= "00" & pseudo_rand(31 DOWNTO 24);
			flag_rst := '1';
			flag_wall1 := '0';
			flag_wall2 := '0';
		ELSIF rising_edge(CLK_24MHz) THEN
			IF (end_game = '0') THEN
				IF (flag_rst = '1') THEN
					IF (flag_wall1 = '1') THEN
						pseudo_rand <= lfsr32(pseudo_rand);
						p_rand1 <= "00" & pseudo_rand(7 DOWNTO 0); -- generate random for first wall
						flag_wall1 := '0';
					END IF;
					IF (flag_wall2 = '1') THEN
						pseudo_rand <= lfsr32(pseudo_rand);
						p_rand2 <= "00" & pseudo_rand(31 DOWNTO 24);-- generate random for second wall
						flag_wall2 := '0';
					END IF;
				END IF;
			END IF;
			IF (wallX1 + SquareWidth + SquareWidth = "0000000000") THEN
				flag_wall1 := '1';
			END IF;
			IF (wallX2 + SquareWidth + SquareWidth = "0000000000") THEN
				flag_wall2 := '1';
			END IF;
		END IF;
	END PROCESS;

	square : PROCESS (CLK_24MHz, IsOutGame)
		VARIABLE flag_btn : BIT := '0';
		VARIABLE lock_key : INTEGER RANGE 0 TO 3 := 2;
		VARIABLE timer_up_key : INTEGER RANGE 0 TO 6 := 0;
	BEGIN
		--initialization
		IF IsOutGame = '0' THEN
			Prescaler <= (OTHERS => '0');
			SquareX <= "0001111000";
			SquareY <= "0011100000";
			flag_btn := '0';
			lock_key := 2;
			timer_up_key := 0;
		ELSIF rising_edge(CLK_24MHz) THEN
			IF (end_game = '0') THEN
				Prescaler <= Prescaler + 1;
				IF Prescaler = "0111010100110000000" THEN -- Activated every 0,01 sec
					--wall moves upward when player pushes button
					IF (key(0) = '0') THEN
						flag_btn := '1';
						lock_key := 1;
					END IF;
					IF (lock_key = 1) THEN
						timer_up_key := timer_up_key + 1;
					END IF;

					IF (timer_up_key = 5) THEN
						timer_up_key := 0;
						lock_key := 0;
					END IF;

					IF (lock_key = 1) THEN

						IF SquareY > SquareYmin THEN
							SquareY <= SquareY - 1;

						ELSE
							SquareY <= SquareY;
						END IF;
					ELSIF (lock_key = 0 AND flag_btn = '1') THEN
						IF SquareY < SquareYmax THEN
							SquareY <= SquareY + 1; -- in default square moves downward
						ELSE
							SquareY <= SquareY;
						END IF;
					END IF;
					Prescaler <= (OTHERS => '0');
				END IF;
			END IF;
		END IF;
	END PROCESS square;

	wall : PROCESS (CLK_24MHz, IsOutGame)
		VARIABLE flag_btn : BIT := '0';
		VARIABLE time_wall : STD_LOGIC_VECTOR(20 DOWNTO 0) := "001110101001100000000"; --0.02s
		VARIABLE counter_15s : INTEGER := 360000000;
		VARIABLE Prescaler_wall : STD_LOGIC_VECTOR(26 DOWNTO 0) := (OTHERS => '0');
	BEGIN
		--initialization
		IF IsOutGame = '0' THEN
			Prescaler_wall := (OTHERS => '0');
			flag_btn := '0';
			time_wall := "001110101001100000000";
			wallX1 <= "0111111000";
			wallY1 <= "0001110000";
			wallX2 <= "1111100000";
			wallY2 <= "0001110000";
		ELSIF rising_edge(CLK_24MHz) THEN
			IF (end_game = '0') THEN
				IF (key(0) = '1') THEN
					flag_btn := '1';
				END IF;
				IF (flag_btn = '1') THEN
					Prescaler_wall := Prescaler_wall + 1;
					IF (counter_15s = 0) THEN
						counter_15s := 360000000;--15 x 24MHz
						time_wall := time_wall - ('0' & time_wall(20 DOWNTO 1));-- this formula helps to move walls faster (every 15 second)
					END IF;
					counter_15s := counter_15s - 1;

					IF (Prescaler_wall = time_wall) THEN -- Activated every time_wall sec, dynamic clock divider
						IF (flag_btn = '1') THEN
							wallX1 <= wallX1 - 1;
							wallX2 <= wallX2 - 1;
						END IF;
						Prescaler_wall := (OTHERS => '0');
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS wall;

	--this process detects conflict to walls
	PROCESS (CLK_24MHz, IsOutGame)
	BEGIN
		IF IsOutGame = '0' THEN
			lose <= '0';
		ELSIF (rising_edge(CLK_24MHz)) THEN -- conflict to first wall
			IF (((wallX1 <= SquareX + SquareWidth AND wallX1 >= SquareX) OR (wallX1 + SquareWidth >= SquareX AND wallX1 <= SquareX))
				AND (SquareY <= p_rand1 OR SquareY + squareWidth >= p_rand1 + squareWidth + squareWidth + squareWidth + SquareWidth)) THEN
				lose <= '1';
			END IF;
			--conflict to second wall
			IF (((wallX2 <= SquareX + SquareWidth AND wallX2 >= SquareX) OR (wallX2 + SquareWidth >= SquareX AND wallX2 <= SquareX))
				AND (SquareY <= p_rand2 OR SquareY + squareWidth >= p_rand2 + squareWidth + squareWidth + squareWidth + SquareWidth)) THEN
				lose <= '1';
			END IF;
		END IF;
	END PROCESS;

	--flag_plus : 0-> initial state, 1 -> must increment score , 2 -> scre is incremented and we are in area after wall
	PROCESS (CLK_24MHz, IsOutGame)
		VARIABLE flag_rst : BIT := '0';
		VARIABLE flag_plus1 : INTEGER RANGE 0 TO 3 := 0;
		VARIABLE flag_plus2 : INTEGER RANGE 0 TO 3 := 0;
	BEGIN
		IF (IsOutGame = '0') THEN
			flag_rst := '1';
			score_signal <= 0;
			flag_plus1 := 0;
			flag_plus2 := 0;
		ELSIF rising_edge(CLK_24MHz) THEN
			IF (flag_rst = '1') THEN
				IF (flag_plus1 = 1) THEN
					score_signal <= score_signal + 1;
					flag_plus1 := 2;
				END IF;
				IF (flag_plus2 = 1) THEN
					score_signal <= score_signal + 1;
					flag_plus2 := 2;
				END IF;
				IF (wallX1 + squareWidth < squareX AND wallX2 > squareX AND flag_plus1 /= 2) THEN
					flag_plus1 := 1;
				END IF;
				IF (wallX2 + squarewidth < squareX AND flag_plus2 /= 2) THEN
					flag_plus2 := 1;
				END IF;
				IF (wallX1 + SquareWidth + SquareWidth = "0000000000") THEN
					flag_plus1 := 0;
				END IF;
				IF (wallX2 + SquareWidth + SquareWidth = "0000000000") THEN
					flag_plus2 := 0;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	score <= score_signal;
	isStarted <= IsOutGame;

	--display: 1.square, 2.perimeter, 3.first wall, 4.second wall, 5.background
	ColorOutput2 <= "000000000000" WHEN (ScanlineX = SquareX + 7 AND ScanlineY = SquareY + 7) OR (ScanlineX = SquareX + 8 AND ScanlineY = SquareY + 7) OR (ScanlineX = SquareX + 7 AND ScanlineY = SquareY + 8) OR (ScanlineX = SquareX + 8 AND ScanlineY = SquareY + 8)
		ELSE
		"000000000000" WHEN (ScanlineX = SquareX + SquareWidth - 7 AND ScanlineY = SquareY + 7) OR (ScanlineX = SquareX + SquareWidth - 8 AND ScanlineY = SquareY + 7) OR (ScanlineX = SquareY + SquareWidth - 7 AND ScanlineX = SquareY + 8) OR (ScanlineX = SquareY + SquareWidth - 8 AND ScanlineX = SquareY + 8)
		ELSE
		"000000000000" WHEN ScanlineY = SquareY + SquareWidth - 7 AND (ScanlineX > SquareX + 7 AND ScanlineX < SquareX + SquareWidth - 7)
		ELSE
		"000000000000" WHEN (ScanlineX = SquareX + 7 OR ScanlineX = SquareX + SquareWidth - 7) AND (ScanlineY > SquareY + SquareWidth - 12 AND ScanlineY < SquareY + SquareWidth - 7)
		ELSE
		"000011110000" WHEN (score_signal = 0) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"111100000000" WHEN (score_signal = 1) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"000000001111" WHEN (score_signal = 2) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"111100001111" WHEN (score_signal = 3) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"000011111111" WHEN (score_signal = 4) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"000011111100" WHEN (score_signal = 5) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"111111001111" WHEN (score_signal = 6) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"000011111111" WHEN (score_signal = 7) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"111111110000" WHEN (score_signal = 8) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"111100000011" WHEN (score_signal = 9) AND (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX + SquareWidth AND ScanlineY < SquareY + SquareWidth)
		ELSE
		"111111111111" WHEN (ScanlineX = SquareX AND ScanlineY > SquareY AND ScanlineY < SquareY + SquareWidth) OR (ScanlineY = SquareY AND ScanlineX > SquareX AND ScanlineX < SquareX + SquareWidth)
		OR (ScanlineX = SquareX + SquareWidth AND ScanlineY > SquareY AND ScanlineY < SquareY + SquareWidth) OR (ScanlineY = SquareY + SquareWidth AND ScanlineX > SquareX AND ScanlineX < SquareX + SquareWidth)
		ELSE
		"111111000000" WHEN ScanlineX >= wallX1 AND ScanlineX < wallX1 + SquareWidth AND (ScanlineY < p_rand1 OR ScanlineY > p_rand1 + SquareWidth + SquareWidth + SquareWidth + SquareWidth)
		ELSE
		"111111110000" WHEN ScanlineX >= wallX2 AND ScanlineX < wallX2 + SquareWidth AND (ScanlineY < p_rand2 OR ScanlineY > p_rand2 + SquareWidth + SquareWidth + SquareWidth + SquareWidth)
		ELSE
		"000000000000" WHEN score_signal = 10
		ELSE
		"111111111111" WHEN (ScanlineY > "1111101" AND ScanlineY < "10010110" AND ScanlineX > "1100100" AND ScanlineX < "10001100")
		OR (ScanlineY >= "10010110" AND ScanlineY <= "10101111"AND ScanlineX > "1001011" AND ScanlineX < "11001000")
		OR (ScanlineY > "10101111" AND ScanlineY < "11001000" AND ScanlineX > "110010" AND ScanlineX < "11111010")
		OR (ScanlineY > ("11001000") AND ScanlineY < ("11100001") AND ScanlineX > ("100101100") AND ScanlineX < ("101011110"))
		OR (ScanlineY >= ("11100001") AND ScanlineY <= ("11111010")AND ScanlineX > ("100010011") AND ScanlineX < ("110010000"))
		OR (ScanlineY > ("11111010") AND ScanlineY < ("100010011") AND ScanlineX > ("11111010") AND ScanlineX < ("111000010"))
		ELSE
		"000000001111";

	positionx <= to_integer(unsigned(scanlinex)) WHEN to_integer(unsigned(scanlinex)) >= 0 AND to_integer(unsigned(scanlinex)) < 640 ELSE
		0;
	positiony <= to_integer(unsigned(scanliney)) WHEN to_integer(unsigned(scanliney)) >= 0 AND to_integer(unsigned(scanliney)) < 480 ELSE
		0;

	PROCESS (positionx, positiony, entitycolor, entitydirection)
	BEGIN
	  scaled_y <= positiony * 360 / 450;  -- Map y to 0-360
	  scaled_x <= positionx * 360 / 450;  -- Map x to 0-360

	  	hue <= (scaled_x + scaled_y) mod 360;
		-- Convert Hue to RGB
		if hue < 60 then
			red   <= 15;
			green <= (hue * 15) / 60;
			blue  <= 0;
		elsif hue < 120 then
			red   <= ((120 - hue) * 15) / 60;
			green <= 15;
			blue  <= 0;
		elsif hue < 180 then
			red   <= 0;
			green <= 15;
			blue  <= ((hue - 120) * 15) / 60;
		elsif hue < 240 then
			red   <= 0;
			green <= ((240 - hue) * 15) / 60;
			blue  <= 15;
		elsif hue < 300 then
			red   <= ((hue - 240) * 15) / 60;
			green <= 0;
			blue  <= 15;
		else
			red   <= 15;
			green <= 0;
			blue  <= ((360 - hue) * 15) / 60;
		end if;

	
		ColorOutput <=  "000000000000";

		IF(reachEnd = '1') THEN
        -- Default color is sky
        ColorOutPut <= COLOR_SKY;

        -- Sun: Circle centered at (80, 80), radius 40
        if (positionx - 80)**2 + (positiony - 80)**2 <= 1600 then
            ColorOutPut <= COLOR_SUN;
        end if;

        -- Grass: Bottom portion of the screen
        if positiony >= 300 then
            ColorOutPut <= COLOR_GRASS;

            -- Tree trunk: A rectangle at (150, 350) to (170, 480)
            if positionx >= 150 and positionx <= 170 and positiony >= 350 then
                ColorOutPut <= COLOR_TREE;
            end if;

            -- Tree leaves: A circle above the trunk centered at (160, 320), radius 50
            if (positionx - 160)**2 + (positiony - 320)**2 <= 2500 then
                ColorOutPut <= COLOR_LEAVES;
            end if;

            -- Cat body: A rectangle at (400, 400) to (430, 450)
            if positionx >= 400 and positionx <= 430 and positiony >= 400 and positiony <= 450 then
                ColorOutPut <= COLOR_CAT;

                -- Cat eyes: Two small circles at (410, 410) and (420, 410)
                if (positionx - 410)**2 + (positiony - 410)**2 <= 4 or (positionx - 420)**2 + (positiony - 410)**2 <= 4 then
                    ColorOutPut <= COLOR_CAT_EYE;
                end if;

                -- Cat ears: Two triangles at the top of the rectangle
                if (positionx >= 405 and positionx <= 410 and positiony = 400) or
                   (positionx >= 420 and positionx <= 425 and positiony = 400) then
                    ColorOutPut <= COLOR_CAT;
                end if;
            end if;
        end if;
		ELSIF (positionx > (MAP_SIZE * BLOCK_SIZE) - 1) OR (positiony > (MAP_SIZE * BLOCK_SIZE) - 1) THEN
			ColorOutput <= "111111111111";
		ELSIF gen_map(positionx, positiony) = "0010" THEN
			ColorOutput <= std_logic_vector(to_unsigned((red * 256) + (green * 16) + blue, 12));	
		ELSIF gen_map(positionx, positiony) = "0100" THEN
			ColorOutput <= std_logic_vector(to_unsigned((red * 256) + (green * 16) + blue, 12));	
		ELSIF gen_map(positionx, positiony) = "0000" THEN
			ColorOutput <= std_logic_vector(to_unsigned((red * 256) + (green * 16) + blue, 12));	
		ELSIF gen_map(positionx, positiony) = "0001" THEN
			ColorOutput <= std_logic_vector(to_unsigned((red * 256) + (green * 16) + blue, 12));	
		ELSIF gen_map(positionx, positiony) = "0110" THEN
			ColorOutput <= std_logic_vector(to_unsigned((red * 256) + (green * 16) + blue, 12));	
		ELSIF gen_map(positionx, positiony) = "1111" THEN
			ColorOutput <= entity_shape(positionx, positiony, entitycolor, entitydirection);
		ELSIF gen_map(positionx, positiony) = "1001" THEN
			ColorOutput <= speed_shape(positionx, positiony);
		ELSIF gen_map(positionx, positiony) = "1010" THEN
			ColorOutput <= ghost_shape(positionx, positiony);
		ELSIF gen_map(positionx, positiony) = "1011" THEN
			ColorOutput <= map_shape(positionx, positiony);
		ELSIF gen_map(positionx, positiony) = "1100" THEN
			ColorOutput <= resize_shape(positionx, positiony);
		ELSIF gen_map(positionx, positiony) = "1110" THEN
			ColorOutput <= enemy_shape(positionx, positiony);
		END IF;
	END PROCESS;


	ColorOut <= ColorOutput WHEN MyGameState /= OUTER_GAME else
	ColorOutput2;

	SquareXmax <= "1010000000" - SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000" - SquareWidth; -- (480 - SquareWidth)
END Behavioral;


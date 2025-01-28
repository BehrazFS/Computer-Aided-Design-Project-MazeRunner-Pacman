-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY CAD_VGA_Quartus IS
	PORT (
		--//////////// CLOCK //////////
		CLOCK_50 : IN STD_LOGIC;
		CLOCK2_50 : IN STD_LOGIC;
		CLOCK3_50 : IN STD_LOGIC;
		CLOCK4_50 : INOUT STD_LOGIC;

		--//////////// KEY //////////
		RESET_N : IN STD_LOGIC;
		Key : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

		--//////////// SEG7 //////////
		HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);

		--//////////// LED //////////
		LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);

		--//////////// SWITCH //////////
		SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);

		--//////////// SDRAM //////////
		DRAM_ADDR : OUT STD_LOGIC_VECTOR (12 DOWNTO 0);
		DRAM_BA : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
		DRAM_CAS_N : OUT STD_LOGIC;
		DRAM_CKE : OUT STD_LOGIC;
		DRAM_CLK : OUT STD_LOGIC;
		DRAM_CS_N : OUT STD_LOGIC;
		DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		DRAM_LDQM : OUT STD_LOGIC;
		DRAM_RAS_N : OUT STD_LOGIC;
		DRAM_UDQM : OUT STD_LOGIC;
		DRAM_WE_N : OUT STD_LOGIC;

		--//////////// microSD Card //////////
		SD_CLK : OUT STD_LOGIC;
		SD_CMD : INOUT STD_LOGIC;
		SD_DATA : INOUT STD_LOGIC_VECTOR(3 DOWNTO 0);

		--//////////// PS2 //////////
		PS2_CLK : INOUT STD_LOGIC;
		PS2_CLK2 : INOUT STD_LOGIC;
		PS2_DAT : INOUT STD_LOGIC;
		PS2_DAT2 : INOUT STD_LOGIC;

		--//////////// VGA //////////
		VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_HS : OUT STD_LOGIC;
		VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_VS : OUT STD_LOGIC
	);
END CAD_VGA_Quartus;

--}} End of automatically maintained section

ARCHITECTURE CAD_VGA_Quartus OF CAD_VGA_Quartus IS

	COMPONENT VGA_controller
		PORT (
			CLK_50MHz : IN STD_LOGIC;
			VS : OUT STD_LOGIC;
			HS : OUT STD_LOGIC;
			RED : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			GREEN : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			BLUE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			RESET : IN STD_LOGIC;
			ColorIN : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
			ScanlineX : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
			ScanlineY : OUT STD_LOGIC_VECTOR(10 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT Maze_Game
		PORT (
			CLK_50MHz : IN STD_LOGIC;
			RESET : IN STD_LOGIC;
			ColorOut : OUT STD_LOGIC_VECTOR(11 DOWNTO 0); -- RED & GREEN & BLUE
			SQUAREWIDTH : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			ScanlineX : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
			ScanlineY : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
			key : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			-- New Game
			end_game : IN BIT;
			score : OUT INTEGER;
			lose : OUT BIT;
			isStarted : OUT STD_LOGIC;
 
			HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL Counter : INTEGER;
	SIGNAL ScanlineX, ScanlineY : STD_LOGIC_VECTOR(10 DOWNTO 0);
	SIGNAL ColorTable : STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL CLOCK_24 : STD_LOGIC;

	--seven_segment...
	SIGNAL isStarted : STD_LOGIC;
	SIGNAL output2 : std_logic_vector(7 DOWNTO 0) := x"c0";
	SIGNAL input2 : INTEGER RANGE 0 TO 100 := 0;
	SIGNAL timer_game : INTEGER RANGE 0 TO 100 := 0;
	SIGNAL end_game : BIT := '0';
	SIGNAL score : INTEGER;
	SIGNAL lose : BIT;
	SIGNAL leds_signal : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101010";

BEGIN

	PROCESS (CLOCK3_50, isStarted)
	BEGIN
		IF (isStarted = '0') THEN
			CLOCK_24 <= '0';
		ELSIF (rising_edge(CLOCK3_50)) THEN
			CLOCK_24 <= NOT CLOCK_24;
		END IF;
	END PROCESS;

	--------- VGA Controller -----------
	VGA_Control : vga_controller
	PORT MAP(
		CLK_50MHz => CLOCK3_50,
		VS => VGA_VS,
		HS => VGA_HS,
		RED => VGA_R,
		GREEN => VGA_G,
		BLUE => VGA_B,
		RESET => NOT RESET_N,
		ColorIN => ColorTable,
		ScanlineX => ScanlineX,
		ScanlineY => ScanlineY
	);

	--------- Maze Game -----------
	VGA_MG : Maze_Game

	PORT MAP(
		CLK_50MHz => CLOCK3_50,
		RESET => NOT RESET_N,
		ColorOut => ColorTable,
		SQUAREWIDTH => "00011001",
		ScanlineX => ScanlineX,
		ScanlineY => ScanlineY,
		key => NOT key,
		end_game => end_game,
		score => score,
		lose => lose,
		isStarted => isStarted,
		HEX0 => HEX0,
		HEX1 => HEX1,
		HEX2 => HEX2,
		HEX3 => HEX3,
		HEX4 => HEX4,
		HEX5 => HEX5,
		LEDR => LEDR
	);
	PROCESS (CLOCK_24, isStarted)
		VARIABLE flag_key : BIT := '0';
		VARIABLE flag_rst : BIT := '0';
		VARIABLE counter : INTEGER RANGE 0 TO 24000000 := 0;
	BEGIN
		IF isStarted = '0' THEN
			flag_key := '0';
			flag_rst := '1';
			counter := 0;
			timer_game <= 0;
		ELSIF (rising_edge(CLOCK_24)) THEN
			IF (key(0) = '0' AND flag_rst = '1') THEN
				flag_key := '1';
			END IF;
			IF (flag_key = '1') THEN
				counter := counter + 1;
				IF (counter = 23999999) THEN
					counter := 0;
					IF (end_game = '1') THEN
						timer_game <= timer_game;
					ELSE
						timer_game <= timer_game + 1; --Add timer after 24000000 clk edge
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	--this process detects when game is finished . in three case it happens : 
	--1.score = 10(win) 2.timer_game(time is end) 3.iose = 1 (conflict happens)
	PROCESS (timer_game)
	BEGIN
		IF (score = 10 OR timer_game = 99 OR lose = '1') THEN
			end_game <= '1';
		ELSE
			end_game <= '0';
		END IF;
	END PROCESS;

	
	-- PROCESS (RESET_N, CLOCK_24)
	-- 	VARIABLE flag_key : BIT := '0';--flag = 0 -> button is not pressed, flag = 1-> button is pressed
	-- BEGIN
	-- 	--here content of segments is "2219"
	-- 	IF RESET_N = '0' THEN
	-- 		-- display IDs
	-- 		HEX0 <= x"a4";
	-- 		HEX1 <= x"a4";
	-- 		HEX2 <= x"f9";
	-- 		HEX3 <= x"98";
	-- 		flag_key := '0';
	-- 	ELSIF (rising_edge(CLOCK_24)) THEN
	-- 		IF (key(0) = '0') THEN
	-- 			flag_key := '1';
	-- 		END IF;
	-- 		--this case shows score in 7 segment
	-- 		IF (flag_key = '1' AND end_game = '0') THEN
	-- 			CASE score IS
	-- 				WHEN 0 => HEX3 <= x"c0";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 1 => HEX3 <= x"F9";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 2 => HEX3 <= x"A4";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 3 => HEX3 <= x"B0";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 4 => HEX3 <= x"99";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 5 => HEX3 <= x"92";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 6 => HEX3 <= x"82";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 7 => HEX3 <= x"F8";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 8 => HEX3 <= x"80";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 9 => HEX3 <= x"98";
	-- 					HEX2 <= x"c0";
	-- 				WHEN 10 => HEX3 <= x"c0";
	-- 					HEX2 <= x"F9";
	-- 				WHEN OTHERS => HEX3 <= x"c0";
	-- 					HEX2 <= x"c0";
	-- 			END CASE;
	-- 			IF (timer_game >= 90) THEN
	-- 				input2 <= timer_game - 90; --to calculate firs digit of timer
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"98";
	-- 			ELSIF (timer_game >= 80) THEN
	-- 				input2 <= timer_game - 80;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"80";
	-- 			ELSIF (timer_game >= 70) THEN
	-- 				input2 <= timer_game - 70;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"F8";
	-- 			ELSIF (timer_game >= 60) THEN
	-- 				input2 <= timer_game - 60;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"82";
	-- 			ELSIF (timer_game >= 50) THEN
	-- 				input2 <= timer_game - 50;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"92";
	-- 			ELSIF (timer_game >= 40) THEN
	-- 				input2 <= timer_game - 40;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"99";
	-- 			ELSIF (timer_game >= 30) THEN
	-- 				input2 <= timer_game - 30;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"B0";
	-- 			ELSIF (timer_game >= 20) THEN
	-- 				input2 <= timer_game - 20;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"A4";
	-- 			ELSIF (timer_game >= 10) THEN
	-- 				input2 <= timer_game - 10;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"F9";
	-- 			ELSE
	-- 				input2 <= timer_game;
	-- 				HEX1 <= output2;
	-- 				HEX0 <= x"C0";
	-- 			END IF;
	-- 		END IF;
	-- 		IF (lose = '1' OR timer_game = 99) THEN
	-- 			HEX0 <= x"c7";
	-- 			HEX1 <= x"c0";
	-- 			HEX2 <= x"92";
	-- 			HEX3 <= x"86";
	-- 		END IF;
	-- 		IF (score = 10) THEN
	-- 			HEX0 <= x"92";
	-- 			HEX1 <= x"c1";
	-- 			HEX2 <= x"c6";
	-- 			HEX3 <= x"c6";
	-- 		END IF;
	-- 	END IF;
	-- END PROCESS;

	-- --equal value of integer input2 in binary format to send to segment
	-- PROCESS (input2)
	-- BEGIN
	-- 	CASE input2 IS
	-- 		WHEN 0 => output2 <= x"c0";
	-- 		WHEN 1 => output2 <= x"F9";
	-- 		WHEN 2 => output2 <= x"A4";
	-- 		WHEN 3 => output2 <= x"B0";
	-- 		WHEN 4 => output2 <= x"99";
	-- 		WHEN 5 => output2 <= x"92";
	-- 		WHEN 6 => output2 <= x"82";
	-- 		WHEN 7 => output2 <= x"F8";
	-- 		WHEN 8 => output2 <= x"80";
	-- 		WHEN OTHERS => output2 <= x"98";
	-- 	END CASE;
	-- END PROCESS;

	
END CAD_VGA_Quartus;
LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.MazeTypes.ALL;

ENTITY MazeGen IS
    GENERIC (
        BLOCK_SIZE : POSITIVE := 50;
        WALL_SIZE : POSITIVE := 20;
        MAP_SIZE : POSITIVE := 9
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        regenEn : IN STD_LOGIC;
        mazeOut : OUT Maze (MAP_SIZE - 1 DOWNTO 0, MAP_SIZE - 1 DOWNTO 0);
        mazeState : OUT MapGenerateState
    );
END ENTITY MazeGen;

ARCHITECTURE MazeBehv OF MazeGen IS

    TYPE StackArray IS ARRAY(MAP_SIZE * MAP_SIZE - 1 DOWNTO 0) OF StackObj;
    SIGNAL mazeArray : Maze (MAP_SIZE - 1 DOWNTO 0, MAP_SIZE - 1 DOWNTO 0);
    SIGNAL stack : StackArray;
    SIGNAL mapState, mapNextState : MapGenerateState;
    SIGNAL stackPointer : INTEGER RANGE -1 TO 81;
    SIGNAL randomNum : INTEGER RANGE 0 TO 3;
    SIGNAL pseudoRand : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL isRegened : STD_LOGIC;

BEGIN

    PROCESS (clk)
        FUNCTION lfsr32(x : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        BEGIN
            RETURN x(30 DOWNTO 0) & (x(0) XNOR x(1) XNOR x(21) XNOR x(31));
        END FUNCTION;
    BEGIN
        IF rising_edge(clk) THEN
            pseudoRand <= lfsr32(pseudoRand);
            randomNum <= to_integer(unsigned(pseudoRand(1 DOWNTO 0)));
        END IF;
    END PROCESS;

    Genrate_Map_Process : PROCESS (clk, reset)
        VARIABLE direction : INTEGER;
    BEGIN
        IF (reset = '1') THEN
            mapState <= NOT_INIT;
            mazeArray <= (OTHERS => (OTHERS => "0000"));
            stackPointer <= - 1;
            isRegened <= '0';
        ELSIF (clk'event AND clk = '1') THEN
            IF (mapState = NOT_INIT) THEN
                stackPointer <= 0;
                stack(0).i <= 0;
                stack(0).j <= 0;
                stack(0).validMoves <= "0000";
                mazeArray <= (OTHERS => (OTHERS => "0000"));
                mapState <= GENERATING;
            ELSIF (mapState = GENERATING) THEN
                IF (stackPointer =- 1) THEN
                    mazeArray(0, 0)(3) <= '1';
                    mazeArray(Map_Size - 1, Map_Size - 1)(1) <= '1';
                    mapState <= END_GENERATE;
                ELSE
                    IF (stack(stackPointer).validMoves = "1111") THEN
                        stackPointer <= stackPointer - 1;
                    ELSE
                        IF (stack(stackPointer).validMoves(randomNum) = '0') THEN
                            direction := randomNum;
                        ELSIF (stack(stackPointer).validMoves((randomNum + 1) MOD 4) = '0') THEN
                            direction := (randomNum + 1) MOD 4;
                        ELSIF (stack(stackPointer).validMoves((randomNum + 2) MOD 4) = '0') THEN
                            direction := (randomNum + 2) MOD 4;
                        ELSIF (stack(stackPointer).validMoves((randomNum + 3) MOD 4) = '0') THEN
                            direction := (randomNum + 3) MOD 4;
                        END IF;
                        IF (stack(stackPointer).validMoves(direction) = '0') THEN
                            IF (direction = 0) THEN
                                IF (stack(stackPointer).i = 0) THEN
                                    stack(stackPointer).validMoves(0) <= '1';
                                ELSIF (mazeArray(stack(stackPointer).i - 1, stack(stackPointer).j) = "0000") THEN
                                    stack(stackPointer + 1).i <= stack(stackPointer).i - 1;
                                    stack(stackPointer + 1).j <= stack(stackPointer).j;
                                    stack(stackPointer).validMoves(0) <= '1';
                                    stack(stackPointer + 1).validMoves <= "0010";
                                    mazeArray(stack(stackPointer).i - 1, stack(stackPointer).j)(1) <= '1';
                                    mazeArray(stack(stackPointer).i, stack(stackPointer).j)(0) <= '1';
                                    stackPointer <= stackPointer + 1;
                                ELSE
                                    stack(stackPointer).validMoves(0) <= '1';
                                END IF;
                            ELSIF (direction = 1) THEN
                                IF (stack(stackPointer).i = MAP_SIZE - 1) THEN
                                    stack(stackPointer).validMoves(1) <= '1';
                                ELSIF (mazeArray(stack(stackPointer).i + 1, stack(stackPointer).j) = "0000") THEN
                                    stack(stackPointer + 1).i <= stack(stackPointer).i + 1;
                                    stack(stackPointer + 1).j <= stack(stackPointer).j;
                                    stack(stackPointer).validMoves(1) <= '1';
                                    stack(stackPointer + 1).validMoves <= "0001";
                                    mazeArray(stack(stackPointer).i + 1, stack(stackPointer).j)(0) <= '1';
                                    mazeArray(stack(stackPointer).i, stack(stackPointer).j)(1) <= '1';
                                    stackPointer <= stackPointer + 1;
                                ELSE
                                    stack(stackPointer).validMoves(1) <= '1';
                                END IF;
                            ELSIF (direction = 2) THEN
                                IF (stack(stackPointer).j = MAP_SIZE - 1) THEN
                                    stack(stackPointer).validMoves(2) <= '1';
                                ELSIF (mazeArray(stack(stackPointer).i, stack(stackPointer).j + 1) = "0000") THEN
                                    stack(stackPointer + 1).i <= stack(stackPointer).i;
                                    stack(stackPointer + 1).j <= stack(stackPointer).j + 1;
                                    stack(stackPointer).validMoves(2) <= '1';
                                    stack(stackPointer + 1).validMoves <= "1000";
                                    mazeArray(stack(stackPointer).i, stack(stackPointer).j)(2) <= '1';
                                    mazeArray(stack(stackPointer).i, stack(stackPointer).j + 1)(3) <= '1';
                                    stackPointer <= stackPointer + 1;
                                ELSE
                                    stack(stackPointer).validMoves(2) <= '1';
                                END IF;
                            ELSIF (direction = 3) THEN
                                IF (stack(stackPointer).j = 0) THEN
                                    stack(stackPointer).validMoves(3) <= '1';
                                ELSIF (mazeArray(stack(stackPointer).i, stack(stackPointer).j - 1) = "0000") THEN
                                    stack(stackPointer + 1).i <= stack(stackPointer).i;
                                    stack(stackPointer + 1).j <= stack(stackPointer).j - 1;
                                    stack(stackPointer).validMoves(3) <= '1';
                                    stack(stackPointer + 1).validMoves <= "0100";
                                    mazeArray(stack(stackPointer).i, stack(stackPointer).j)(3) <= '1';
                                    mazeArray(stack(stackPointer).i, stack(stackPointer).j - 1)(2) <= '1';
                                    stackPointer <= stackPointer + 1;
                                ELSE
                                    stack(stackPointer).validMoves(3) <= '1';
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF (mapState = END_GENERATE) THEN
                    IF (regenEn = '1' AND isRegened = '0') THEN
                        isRegened <= '1';
                        mapState <= NOT_INIT;
                    END IF;
                END IF;
            END IF;
        END PROCESS Genrate_Map_Process;

        mazeout <= mazearray;
        mazeState <= mapState;
    END ARCHITECTURE MazeBehv;
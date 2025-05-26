# Computer-Aided-Design-Project-MazeRunner-Pacman
A game called MazeRunner (that turned into Pacman along the way:) ) implemented in VHDL as an assignment for Digital Systems Analysis & Design(Computer-Aided Design) course at the University of Guilan, 
Instructor: Dr. Mahdi Aminian.

The program was tested on Cyclone® V FPGA using Intel Quartus Prime.
# Game:
the key1 to key4 are used to move up, down, left and right 

the reset key will reset the game 

the game starts by pressing one of the keys

the LEDs show the remaining health

the SevenSegments show the remaining time (99 second total time to finish the game)

you win by getting from the top left corner to the bottom right 

you lose if:<br>
1.the timer runs out<br>
2.your health reaches 0<br>
3.you collide with the ghost

the potions : <br>
'[!]' : speed up<br>
'[?]' : map regeneration (randomly generated using dfs)<br>
'[/]' : gives 9 seconds of hit immunity <br>
'[+]' : reduces your size<br>

there is an easter-egg in game if you go straight up from starting position:)

# Pictures:

# Team members: 
https://github.com/BehrazFS https://github.com/AhmadReza2003H404

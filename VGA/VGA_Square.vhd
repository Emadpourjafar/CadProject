----------------------------------------------------------------------------------
-- Moving Square Demonstration 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity VGA_Square is
  port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			TouchKey 		: in std_logic_vector(3 downto 0);
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			blockHight		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			CountOut       : out integer;
			finish         : out integer
  );
end VGA_Square;

architecture Behavioral of VGA_Square is



------------------ random generator ------------------

function lfsr32 (x : std_logic_vector(31 downto 0)) return std_logic_vector is
	begin
		return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
end function;

------------------ initial signals ------------------
signal fine : integer := 0;
signal EndGame : integer := 0;
signal Counter : integer:=1;
signal countEnable : integer:=0;
signal Timer : integer:=0;
signal countEn : integer:=0;
signal CounterWon : integer:=1;
signal ColorOutput: std_logic_vector(11 downto 0);
signal SquareXposition: std_logic_vector(9 downto 0):="0101000000" ;  --set first position of square
signal SquareYposition: std_logic_vector(9 downto 0) ;  --set first position of square
signal blockXposition, blockYposition, blockY2position: std_logic_vector(9 downto 0) := "0000000000" ;  --set first position of block
signal blockX2position: std_logic_vector(9 downto 0) := "0111000101" ;  --set first position of block â€­00101000â€¬
signal blockXmax, blockXmin: std_logic_vector(9 downto 0);  
constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
signal RandYPos, RandY2Pos : std_logic_vector(9 downto 0) ;
signal pseudo_rand1, pseudo_rand2  : std_logic_vector(31 downto 0) ;
signal ColorSelect: std_logic_vector(2 downto 0) := "001";
signal Prescaler, BlockPrescaler : std_logic_vector(17 downto 0) := (others => '0');
signal blockSpeed : std_logic_vector(19 downto 0) := "00111101000010010000";
signal temp : std_logic_vector(19 downto 0);
signal SquareXMoveDir : std_logic := '0';
type STATE_TYPE is ( start, waitS, loose,Won);
signal STATE: STATE_TYPE := waitS;
begin
------------------ create square ------------------
	
PrescalerCounter: process(CLK_50Mhz, RESET,CounterWon)
	begin
		if RESET = '1' then
			fine <= 0;
			STATE <= waitS;
			Prescaler <= (others => '0');
			SquareYposition <= "0011110000";
			ColorSelect <= "001";
		elsif (rising_edge(CLK_50Mhz)) then
			case STATE is
				 when start =>
					if(CounterWon< 10 and EndGame = 0 ) then
								Prescaler <= Prescaler + 1;	 
								if Prescaler = "111111111000100000" then  
									if(Touchkey(0)='1') then
										if SquareYposition < SquareYmax then
											SquareYposition <= SquareYposition + 1;
										end if;
										if SquareYposition >= SquareYmax then
											STATE <= loose;
										end if;
									else
										if SquareYposition > SquareYmin then
											SquareYposition <= SquareYposition - 1;
										end if;
										if SquareYposition >= SquareYmax then
											STATE <= loose;
										end if;
									end if;	
								Prescaler <= (others => '0');
								end if;
								if(((squareXposition >= blockXposition - SquareWidth and squareXposition <= blockXposition + SquareWidth) and (SquareYposition <= randYpos or SquareYposition >= randYpos +  SquareWidth + SquareWidth + SquareWidth)) or ((squareXposition >= blockX2position - SquareWidth and squareXposition <= blockX2position + SquareWidth) and (SquareYposition <= randY2pos or SquareYposition >= randY2pos +  SquareWidth + SquareWidth + SquareWidth))) then
										fine <= 1;
										STATE <= loose;
								end if;
					 else
					  fine <= 2;
					  STATE <= Won;
					end if;
					when waitS => 
						if (touchkey(3) = '0') then
							STATE <= start ;
						else
							STATE <= waitS;
						end if;
					when loose => 
							STATE <= loose ;
					when Won =>	
							STATE <= waitS  ;			
							
			end case;
		end if;
	end process PrescalerCounter;
	finish <= fine;

------------------ create blockes ------------------
	
blockCounter: process(CLK_50Mhz, RESET,pseudo_rand1)
	variable tmp : integer := 0;
  
	begin
		if RESET = '1' then
		   counterWon <= 0;
			tmp := 0;
			pseudo_rand1 <= lfsr32(pseudo_rand1);
			BlockPrescaler <= (others => '0');
			blockXposition <= "0000000000";
			blockX2position <= "0111000101";
			ColorSelect <= "001";
		elsif rising_edge(CLK_50Mhz) then
			case STATE is   
				 when start =>
						BlockPrescaler <= BlockPrescaler + 1;	 
						if BlockPrescaler = blockSpeed then 
							if SquareXMoveDir = '0' then
								if blockXposition < SquareXmax then
									blockXposition <= blockXposition + 1;
								else
									pseudo_rand1 <= lfsr32(pseudo_rand2);
									RandYPos <= "00" & pseudo_rand1(7 downto 0);
									blockXposition <= blockX2position - "0111000101";
								end if;
								if blockX2position < SquareXmax then
									blockX2position <= blockX2position + 1;
								else
									pseudo_rand2 <= lfsr32(pseudo_rand2);
									RandY2Pos <= "00" & pseudo_rand2(7 downto 0);
									blockX2position <= blockXposition - "0111000101";
								end if;
								
								if(blockXposition ="0101000000") then
									tmp := tmp + 1;
								elsif(blockX2position ="0101000000") then
									tmp := tmp + 1;
								end if;	
							end if;	
							BlockPrescaler <= (others => '0');
						end if;
					     counterWon <=tmp;
					when loose => 
						
					when waitS => 
					
					when Won =>
					
				end case;
				
		end if;
			
	end process blockCounter;

--counter for increasing speed of blocks	
	process (countEN, CLK_50Mhz,RESET)
	begin
	if RESET = '1' then
		countEN <= 0;
		Counter <= 0;
	elsif (rising_edge(CLK_50Mhz)) then	
		countEN <= countEN + 1;
		if countEN = 50000000 then
			if (Counter < 17 ) then
			   counter <= counter + 1;
				countEn <= 0;
			else
			   blockSpeed <=  blockspeed - 70000;
				countEN <= 0;
				Counter <= 0;
			end if;
		end if;
	end if;
	end process;
	
-- Timer for freezing the game after 99s
	process (countEnable, CLK_50Mhz,RESET)
	begin
	if RESET = '1' then
	   EndGame <= 0;
		Timer <= 0;
		countEnable <= 0;
	elsif (rising_edge(CLK_50Mhz)) then	
		countEnable <= countEnable + 1;
		if countEnable = 50000000 then
		   if(Timer < 101) then
			  countEnable <= 0;
			  Timer <= Timer + 1 ;
			else
			  countEnable <= 0;
			  EndGame <= 1;
			end if;
		end if;
	end if;
	end process;
   countout <= counterWon;
		

------------------ set color -----------------
   colorOutput <= "111101110100" when fine = 1 else "011011010101" when fine = 2 else "101110011101" when ScanlineX >= SquareXposition AND ScanlineY >= SquareYposition AND ScanlineX < (SquareXposition + SquareWidth) AND ScanlineY < (SquareYposition + SquareWidth) 
	else  "010101010101" when ScanlineX >= blockXposition AND ScanlineY >= RandYPos  AND ScanlineX < (blockXposition + SquareWidth) AND ScanlineY < (RandYPos + SquareWidth + SquareWidth + SquareWidth + SquareWidth) 
	else  "111111000100" when ScanlineX >= blockXposition AND ScanlineY >= blockYposition AND ScanlineX < (blockXposition + SquareWidth) AND ScanlineY < ("0111100000")
	else  "010101010101" when ScanlineX >= blockX2position AND ScanlineY >= RandY2Pos  AND ScanlineX < (blockX2position + SquareWidth) AND ScanlineY < (RandY2Pos + SquareWidth + SquareWidth + SquareWidth + SquareWidth) 
	else  "111111000100" when ScanlineX >= blockX2position AND ScanlineY >= blockY2position AND ScanlineX < (blockX2position + SquareWidth) AND ScanlineY < ("0111100000")
	else  "010101010101" ;
					
	ColorOut <= ColorOutput;
   
	SquareXmax <= "1010000000" - SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000" - SquareWidth;	-- (480 - SquareWidth)
end Behavioral;


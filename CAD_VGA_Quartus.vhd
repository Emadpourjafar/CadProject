-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith.ALL;
use IEEE.numeric_std.all;

entity CAD961Test is
	Port(
		--//////////// CLOCK //////////
		CLOCK_50 	: in std_logic;
		CLOCK2_50	: in std_logic;
		CLOCK3_50	: in std_logic;
		CLOCK4_50	: inout std_logic;
		
		--//////////// KEY //////////
		RESET_N	: in std_logic;
		Key 		: in std_logic_vector(3 downto 0);
	
		--//////////// SEG7 //////////
		HEX0	: out std_logic_vector(6 downto 0);
		HEX1	: out std_logic_vector(6 downto 0);
		HEX2	: out std_logic_vector(6 downto 0);
		HEX3	: out std_logic_vector(6 downto 0);
		HEX4	: out std_logic_vector(6 downto 0);
		HEX5	: out std_logic_vector(6 downto 0);
	
		--//////////// LED //////////
		LEDR	: out std_logic_vector(9 downto 0) := "0000000000";
	
		--//////////// SW //////////
		Switch : in std_logic_vector(9 downto 0);
		
		--//////////// SDRAM //////////
		DRAM_ADDR	: out std_logic_vector (12 downto 0);
		DRAM_BA		: out std_logic_vector (1 downto 0); 
		DRAM_CAS_N	: out std_logic;
		DRAM_CKE		: out std_logic;
		DRAM_CLK		: out std_logic;
		DRAM_CS_N	: out std_logic;
		DRAM_DQ		: inout std_logic_vector(15 downto 0);
		DRAM_LDQM	: out std_logic;
		DRAM_RAS_N	: out std_logic;
		DRAM_UDQM	: out std_logic;
		DRAM_WE_N	: out std_logic;
		
		--//////////// microSD Card //////////
		SD_CLK	: out std_logic;
		SD_CMD	: inout std_logic;
		SD_DATA	: inout std_logic_vector(3 downto 0);
		
		--//////////// VGA //////////
		VGA_B		: out std_logic_vector(3 downto 0);
		VGA_G		: out std_logic_vector(3 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(3 downto 0);
		VGA_VS	: out std_logic;
		
		--//////////// GPIO_1, GPIO_1 connect to LT24 - 2.4" LCD and Touch //////////
		MyLCDLT24_ADC_BUSY		: in std_logic;
		MyLCDLT24_ADC_CS_N		: out std_logic;
		MyLCDLT24_ADC_DCLK		: out std_logic;
		MyLCDLT24_ADC_DIN			: out std_logic;
		MyLCDLT24_ADC_DOUT		: in std_logic;
		MyLCDLT24_ADC_PENIRQ_N	: in std_logic;
		MyLCDLT24_CS_N				: out std_logic;
		MyLCDLT24_D					: out std_logic_vector(15 downto 0);
		MyLCDLT24_LCD_ON			: out std_logic;
		MyLCDLT24_RD_N				: out std_logic;
		MyLCDLT24_RESET_N			: out std_logic;
		MyLCDLT24_RS				: out std_logic;
		MyLCDLT24_WR_N				: out std_logic
	);
end CAD961Test;

--}} End of automatically maintained section

architecture CAD961Test of CAD961Test is

Component VGA_controller
	port ( CLK_50MHz		: in std_logic;
         VS					: out std_logic;
			HS					: out std_logic;
			RED				: out std_logic_vector(3 downto 0);
			GREEN				: out std_logic_vector(3 downto 0);
			BLUE				: out std_logic_vector(3 downto 0);
			RESET				: in std_logic;
			ColorIN			: in std_logic_vector(11 downto 0);
			ScanlineX		: out std_logic_vector(10 downto 0);
			ScanlineY		: out std_logic_vector(10 downto 0)
  );
end component;

Component VGA_Square
	port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			TouchKey			: in std_logic_vector(3 downto 0);
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			blockHight		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			CountOut       : out integer;
			finish         : out integer
  );
end component;
	
function convSEG (N : std_logic_vector(3 downto 0)) return std_logic_vector is
variable ans:std_logic_vector(6 downto 0);
begin
	Case N is
		when "0000" => ans:="1000000";	 
		when "0001" => ans:="1111001";
		when "0010" => ans:="0100100";
		when "0011" => ans:="0110000";
		when "0100" => ans:="0011001";
		when "0101" => ans:="0010010";
		when "0110" => ans:="0000010";
		when "0111" => ans:="1111000";
		when "1000" => ans:="0000000";
		when "1001" => ans:="0010000";	   
		when "1010" => ans:="0001000";
		when "1011" => ans:="0000011";
		when "1100" => ans:="1000110";
		when "1101" => ans:="0100001";
		when "1110" => ans:="0000110";
		when "1111" => ans:="0001110";				
		when others => ans:="1111111";
	end case;	
	return ans;
end function convSEG;

signal fine : integer := 0;
signal Counter : integer:=1;
signal countEn, i : integer;
signal x : std_logic_vector(9 downto 0) := "0000000000";
signal yekan : integer;
signal dahgan : integer;
signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
signal ColorTable	: std_logic_vector(11 downto 0);
signal score : integer;
signal squareTable	: std_logic_vector(11 downto 0);
signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth; 111001100
signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
signal SWidth : std_logic_vector(7 downto 0) :="00011110";
signal bHight : std_logic_vector(7 downto 0) :="11100000";
type   STATE_TYPE is ( start, waitS, loose );
signal STATE: STATE_TYPE := waitS;
begin

	 --------- VGA Controller -----------
	 VGA_Control: vga_controller
			port map(
				CLK_50MHz	=> CLOCK3_50,
				VS				=> VGA_VS,
				HS				=> VGA_HS,
				RED			=> VGA_R,
				GREEN			=> VGA_G,
				BLUE			=> VGA_B,
				RESET			=> not RESET_N,
				ColorIN		=> ColorTable,
				ScanlineX	=> ScanlineX,
				ScanlineY	=> ScanlineY
			);
		
		--------- Moving Square -----------
		VGA_SQ: VGA_Square
			port map(
				CLK_50MHz		=> CLOCK3_50,
				RESET				=> not RESET_N,
				Touchkey			=> key,
				ColorOut			=> squareTable,
				SQUAREWIDTH		=> SWidth,
				blockHight		=> bHight,
				ScanlineX		=> ScanlineX,
				ScanlineY		=> ScanlineY,
				countOut       => score,
				finish         => fine
			);
	 
	 --------- 7Segment Show ------------
	 
	 process(Counter, CLOCK_50,score,fine,RESET_N)
	 begin
		 if (RESET_N = '0') then
					STATE <= waitS;
					countEN <= 0;
					Counter <= 1;
					yekan   <= 1;
					dahgan  <= 0;
					HEX2 <= "1111111";
					HEX3 <= "1111111";
					LEDR <= "0000000000";
					
		 elsif (rising_edge(CLOCK_50)) then
			 case STATE is
				 when start =>
				  if(fine = 0) then
					countEN <= countEN + 1;
						if countEN = 50000000 then
							if (Counter < 101 ) then
								countEN <= 0;
								Counter <= Counter + 1;
								yekan <= Counter mod 10;
								dahgan <= Counter / 10;
								HEX2 <= convSEG(std_logic_vector(to_unsigned(yekan,4)));
								HEX3 <= convSEG(std_logic_vector(to_unsigned(dahgan,4)));
								HEX4 <= convSEG(std_logic_vector(to_unsigned(Score,4)));
								STATE <= start;
							else	
								Counter <= 1;
								STATE <= loose ;
								
							end if;
						end if;
					elsif(fine =1) then
					  HEX3 <="1111111";
					  HEX2 <= convSEG(std_logic_vector(to_unsigned(Score,4)));
					  HEX5<="1000111";
					  HEX4<="1000000";
					  HEX1<="0010010";
					  HEX0<="0000110";
					  LEDR<= "1010101010";
					else
					  HEX5<="1000110";
					  HEX4<="1110110";
					  HEX1<="1110110";
					  HEX0<="1110000"; 
--					  i <= i + 1;
--						if i = 500000 then
--							x <= '1' & x(9 downto 1);
--							i <= 0;
--						end if;
--						LEDR <= x;
					  LEDR<= "1111111111";
					end if;
						
				 when waitS =>
					if key(3) = '0' then
							STATE <= start ;
							HEX0 <= "1111111";
							HEX1 <= "1111111";
							HEX4 <= "1111111";
							HEX5 <= "1111111";
					else
							STATE <= waitS ;
							HEX0 <= convSEG("0010");
							HEX1 <= convSEG("0011");
							HEX4 <= convSEG("0110");
							HEX5 <= convSEG("0000");
					end if ;
					when loose =>
						STATE <= loose ;
						HEX0 <= convSEG("0010");
						HEX1 <= convSEG("0011");
						HEX4 <= convSEG("0110");
						HEX5 <= convSEG("0000");
			end case;
		 end if;
	 end process ;
	 colorTable <=  squareTable ;
end CAD961Test;

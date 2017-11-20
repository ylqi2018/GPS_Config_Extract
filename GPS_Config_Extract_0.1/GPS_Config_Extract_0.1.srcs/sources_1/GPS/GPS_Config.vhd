
library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_arith.ALL;
use IEEE.std_logic_unsigned.all;

entity GPS_Config is
	port (
		clk			:	in	STD_LOGIC;
		rst			:	in	STD_LOGIC;
		rx			:	in	STD_LOGIC;
		tx			:	out	STD_LOGIC
		);
end GPS_Config;

architecture Behavioral of GPS_Config is
-- =============================================================================
-- component UART
	component uart is
	generic (
		baud                : positive;
		clock_frequency     : positive
		);
	port (  
		clock               :   in  std_logic;
		reset               :   in  std_logic;    
		data_stream_in      :   in  std_logic_vector(7 downto 0);
		data_stream_in_stb  :   in  std_logic;
		data_stream_in_ack  :   out std_logic;
		data_stream_out     :   out std_logic_vector(7 downto 0);
		data_stream_out_stb :   out std_logic;
		tx                  :   out std_logic;
		rx                  :   in  std_logic
		);
	end component; 
-- =============================================================================	
-- type definition
	type tstring is array(natural range<>) of character;

-- config cmd
    constant N2 : natural := 49;
    constant OUTPUT_SET : tstring(0 to N2-1) := "$PMTK314,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*29";	   
	constant N3 : natural := 15;
	constant UPDATA_RATE : tstring(0 to N3-1) := "$PMTK220,100*2F";
	constant N4 : natural := 18;
	constant BAUDRATE : tstring(0 to N4-1) := "$PMTK251,115200*1F";

-- output
signal  model_sel           :   std_logic_vector(2 downto 0);

-- signals inside
signal byte_to_Tx: std_logic_vector(7 downto 0) := (others => '0');
signal send_byte: std_logic_vector(7 downto 0) := (others => '0');
signal index    : std_logic_vector(7 downto 0);
signal length_sig: std_logic_vector(6 downto 0)	:= (others => '0');
signal char_index:  integer range 0 to N2-1;

signal data_stream_in_stb : std_logic	:= '0';
signal  data_stream_in_ack  :   std_logic;
signal  data_stream_out     :   std_logic_vector(7 downto 0); 
signal  data_stream_out_stb :   std_logic;
signal  cmd_over              :   std_logic;

signal  cnt :   std_logic_vector(10 downto 0);

signal  s_clk_20MHz :   std_logic;
signal  s_clk_40MHz :   std_logic;

begin

	process(clk, rst)
	begin 
		if (rst = '1') then
			index <= (others=>'0');
--			cmd_over <= '0';		
			model_sel <= (others => '0');
			char_index <= 0;
			cnt <= (others => '0');
		elsif (clk'event and clk = '1') then			
			case model_sel is 
				when "000" =>
--					length_sig <= conv_std_logic_vector(N1,7);
--					byte_to_tx <= std_logic_vector(to_unsigned(character'pos(OUTPUT_SETTING(char_index)),8));			-- character'pos: Converting characters to their integer (ASCII)
				    send_byte <= x"24";
				when "001" =>
					length_sig<=conv_std_logic_vector(N2,7);
					byte_to_tx<=std_logic_vector(to_unsigned(character'pos(OUTPUT_SET(char_index)),8));	               
				when "010" =>
					length_sig<=conv_std_logic_vector(N3,7);
					byte_to_tx<=std_logic_vector(to_unsigned(character'pos(UPDATA_RATE(char_index)),8));	
				when "011" =>
                    length_sig<=conv_std_logic_vector(N4,7);
                    byte_to_tx<=std_logic_vector(to_unsigned(character'pos(BAUDRATE(char_index)),8));   
				when others =>
					length_sig <=  conv_std_logic_vector(N2,7);
					byte_to_tx<= (others=>'0');
			end case;
			
			if (index < length_sig) then				-- index <= N-1
				char_index <= conv_integer(index);
				send_byte <= byte_to_tx;
				data_stream_in_stb <= '1';
				if (data_stream_in_ack = '1') then 
					data_stream_in_stb <= '0';
					index <= index + 1;					--index will up to N
				end if;
				cmd_over <= '0';
			elsif (index = length_sig) then			--index = N
                send_byte <= x"0D";
                data_stream_in_stb <= '1';
                if (data_stream_in_ack = '1') then      -- why not run? 	
                    data_stream_in_stb <= '0';
                    index <= index + 1;                    --index will up to N
                end if;
                cmd_over <= '0';
			elsif (index = length_sig+1) then
                send_byte <= x"0A";
                data_stream_in_stb <= '1';
				if (data_stream_in_ack = '1') then 	
					data_stream_in_stb <= '0';
                    index <= (others => '0');
                    char_index <= 0;
                    if (model_sel <= 3) then
                        model_sel <= model_sel + 1;
                    else
                        model_sel <= (others => '0');
                    end if;
				end if;
                cmd_over <= '0';
			end if;
		end if;
	end process;

-- =============================================================================
inst_uart_config : uart 
	generic map(
		baud             => 9600   ,        
		clock_frequency  => 100000000
		)
	port map(
		clock               =>  clk         ,
		reset               =>  rst                 ,
		data_stream_in      =>  send_byte			,
		data_stream_in_stb  =>  data_stream_in_stb  ,
		data_stream_in_ack  =>  data_stream_in_ack  ,
		data_stream_out     =>  data_stream_out     ,
		data_stream_out_stb =>  data_stream_out_stb ,
		tx                  =>  tx                  ,
		rx                  =>  rx
		);

end Behavioral;

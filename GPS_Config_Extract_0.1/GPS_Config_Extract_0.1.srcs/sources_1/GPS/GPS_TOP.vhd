
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GPS_TOP is
    port (
        clk     :   in  STD_LOGIC;
        rst     :   in  STD_LOGIC;
        tx		:	out	STD_LOGIC;
        rx		:	in	STD_LOGIC
    );
end GPS_TOP;

architecture Behavioral of GPS_TOP is

-- ##### component GPS_Config #####
component GPS_Config is
port (
	clk			:	in	STD_LOGIC;
	rst			:	in	STD_LOGIC;
	rx			:	in	STD_LOGIC;
	tx			:	out	STD_LOGIC
	);
end component;

-- ##### component GPS_REC #####
component GPS_REC is
Port ( 
	clk 				: in STD_LOGIC;
	rst 				: in STD_LOGIC;
	data_in 			: in STD_LOGIC;
	data_out			: out STD_LOGIC;
	data_out_en_GPS 	: out std_logic;
	data_lati_val_out 	: out std_logic_vector(31 downto 0);
	data_long_val_out 	: out std_logic_vector(31 downto 0);
	GPS_led_valid     	: out std_logic
	);
end component;

begin

inst_GPS_Config: GPS_Config
	port map(
		clk		=> clk,			--:	in	STD_LOGIC;
		rst		=> rst,			--:	in	STD_LOGIC;
		rx		=> rx,			--:	in	STD_LOGIC;
		tx		=> tx			--:	out	STD_LOGIC
	);


end Behavioral;

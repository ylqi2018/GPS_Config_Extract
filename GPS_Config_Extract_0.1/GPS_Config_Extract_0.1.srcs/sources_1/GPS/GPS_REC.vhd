----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2016/09/23 14:40:35
-- Design Name: 
-- Module Name: TOP_UART_Extract - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GPS_REC is
    Port ( 
		clk : in STD_LOGIC;
		rst : in STD_LOGIC;
		data_in : in STD_LOGIC;
		data_out: out STD_LOGIC;
		data_out_en_GPS : out std_logic;
		data_lati_val_out : out std_logic_vector(31 downto 0);
		data_long_val_out : out std_logic_vector(31 downto 0);
		GPS_led_valid     : out std_logic
		);
end GPS_REC;

architecture Behavioral of GPS_REC is
-------------------------------------------------------------------------------------
--clock module
-------------------------------------------------------------------------------------
    component clk_wiz_0 
    port (
         clk_in1    : in    std_logic;  --100MHz
         clk_out1   : out   std_logic;  --20MHz
         clk_out2   : out   std_logic;  --40MHz
         locked      : out    std_logic
         );
     end component;

-------------------------------------------------------------------------------------
--UART module
-------------------------------------------------------------------------------------
    component uart
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
    
-------------------------------------------------------------------------------------
--Extract module
-------------------------------------------------------------------------------------
    component Extract
    	Port ( 
        clk         : in STD_LOGIC;                                   --connect to clk_20MHz
        clk2        : in std_logic;                                   --connect to clk_40MHz
        rst         : in STD_LOGIC;
        data_in     : in STD_LOGIC_VECTOR (7 downto 0);        --connect to UART's data_stream_out, 8 bits
        data_in_en  : in STD_LOGIC;                                 --connect to UART's data_stream_out_stb, 8 bits
        data_out_lati   : out STD_LOGIC_VECTOR (31 downto 0); 	--get $GPGGA... out
        data_out_long   : out std_logic_vector(31 downto 0);
        data_out_ready  : out STD_LOGIC
        );
    end component;
        
-------------------------------------------------------------------------------------
--signals
-------------------------------------------------------------------------------------
    signal  s_clk_20MHz :   std_logic;
    signal  s_clk_40MHz :   std_logic;
    signal  s_uart_data_stream_in : std_logic_vector(7 downto 0) := (others => '0');
    signal  s_uart_data_stream_in_stb : std_logic := '0';
    signal  s_uart_data_stream_in_ack : std_logic := '0';
    signal  s_uart_data_stream_out  : std_logic_vector(7 downto 0);
    signal  s_uart_data_stream_out_stb : std_logic;
    signal  s_uart_tx   : std_logic := '0';
    
    signal  s_Extract_data_out_lati :   std_logic_vector(31 downto 0);
    signal  s_Extract_data_out_long :   std_logic_vector(31 downto 0);
    
    signal  data_out_en_GPS_en      :   std_logic;

begin

data_lati_val_out  <= s_Extract_data_out_lati;
data_long_val_out  <=  s_Extract_data_out_long;


--    clock : clk_wiz_0
--    port map (
--        clk_in1 => clk,
--        clk_out1 => s_clk_20MHz,
--        clk_out2 => s_clk_40MHz,
--        locked => open
--        );
        
inst_uart_extract : uart
    generic map(baud             => 115200   ,        
                  clock_frequency  => 100000000)    
    port map (
        clock => clk,
        reset => rst,    
        data_stream_in => s_uart_data_stream_in,
        data_stream_in_stb  => s_uart_data_stream_in_stb,
        data_stream_in_ack  => s_uart_data_stream_in_ack,
        data_stream_out => s_uart_data_stream_out,
        data_stream_out_stb => s_uart_data_stream_out_stb,
        tx => s_uart_tx,
        rx => data_in
        );
        
    Extract_1 : Extract
    port map (
        clk => clk,   								--connect to clk_20MHz
        clk2 => clk,
        rst => rst,
        data_in => s_uart_data_stream_out,        --connect to UART's data_stream_out, 8 bits
        data_in_en => s_uart_data_stream_out_stb,                               --connect to UART's data_stream_out_stb, 8 bits
        data_out_lati => s_Extract_data_out_lati, 	--get $GPGGA... out
        data_out_long => s_Extract_data_out_long,
        data_out_ready => data_out_en_GPS_en 
        );
        
data_out_en_GPS   <=  data_out_en_GPS_en;
GPS_led_valid     <=  data_out_en_GPS_en;

end Behavioral;

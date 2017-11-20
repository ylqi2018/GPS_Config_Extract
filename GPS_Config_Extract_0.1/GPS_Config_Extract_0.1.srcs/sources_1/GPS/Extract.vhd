----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2016/09/20 10:46:31
-- Design Name: 
-- Module Name: Extract - Behavioral
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

entity Extract is
	Port ( 
        clk             : in  STD_LOGIC;   								--connect to clk_20MHz
        clk2            : in  STD_LOGIC;   								--connect to clk_40MHz		
        rst             : in  STD_LOGIC;
        data_in         : in  STD_LOGIC_VECTOR (7 downto 0);		--connect to UART's data_stream_out, 8 bits
        data_in_en      : in  STD_LOGIC; 								--connect to UART's data_stream_out_stb, 8 bits
        data_out_lati   : out STD_LOGIC_VECTOR (31 downto 0); 	--get $GPGGA... out
        data_out_long   : out std_logic_vector(31 downto 0);
        data_out_ready  : out STD_LOGIC
		);
end Extract;

architecture Behavioral of Extract is
--------------------------------------------------------------------------------
--ILA component, used to analys the extreacted data
--------------------------------------------------------------------------------
    component ila_GPS
    port (
        clk    : IN STD_LOGIC;  
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe8 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe9 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe10 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe11 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe12 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe13 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe14 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

--------------------------------------------------------------------------------
--constant
--------------------------------------------------------------------------------
	CONSTANT BIT_WIDTH     :  integer := 8;
	CONSTANT CMD_DEPTH     :  integer := 6;
	CONSTANT ARRAY_DEPTH   :  integer := 12;
	CONSTANT CNT_WIDTH     :  integer := 7;
	CONSTANT DATA_WIDTH    :  integer := 32;
	
--use to check the data_out right or not, position of Discovery Park
    CONSTANT LATI   :   integer := 33249248;
    CONSTANT LONG   :   integer := 97146411;

--define new data type		
	subtype Byte_sig  is  STD_LOGIC_VECTOR(BIT_WIDTH-1 downto 0);
	
	type CMD_ARRAY is array (0 to CMD_DEPTH-1) of Byte_sig;
	type GPS_ARRAY is array (0 to ARRAY_DEPTH-1) of Byte_sig;
	
    signal correct_word : CMD_ARRAY;    --predefined, used to check the the begin of a GPS signal
    signal input_word   : CMD_ARRAY;    --used to save the data_in    
    signal lati_word    : GPS_ARRAY;    --used to save the latitude, including the point
    signal long_word    : GPS_ARRAY;    --used to save the longitude, including the point

--counters    	
    signal cnt_corr	   :   std_logic_vector(CNT_WIDTH-1 downto 0);  
	signal cnt_comma   :   std_logic_vector(CNT_WIDTH-1 downto 0);     --use to count the number of comma
	signal cnt_lati    :   std_logic_vector(CNT_WIDTH-1 downto 0);
	signal cnt_long    :   std_logic_vector(CNT_WIDTH-1 downto 0);
	
--enable signals
    signal comp            : std_logic;
    signal comma_cnt_en    : std_logic;
    signal lati_en         : std_logic;
    signal long_en         : std_logic;
    signal lati_ready      : std_logic;
    signal long_ready      : std_logic;

--used to save the extracted data, 32 bits	
	signal data_lati       : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	signal data_lati_reg   : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	signal data_lati_l1    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	signal data_lati_l3    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

	signal data_long       : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	signal data_long_reg   : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	signal data_long_l1    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
	signal data_long_l3    : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
		
--use to check
    signal DATA_LATI_CHECK    : std_logic_vector(31 downto 0);      --predefined
    signal DATA_LONG_CHECK    : std_logic_vector(31 downto 0);
    
    signal err_lati : std_logic_vector(31 downto 0);
    signal err_long : std_logic_vector(31 downto 0);
    signal err_lati_abs : std_logic_vector(31 downto 0);
    signal err_long_abs : std_logic_vector(31 downto 0);

--    
    signal s_data_out_lati : std_logic_vector(31 downto 0);
    signal s_data_out_long : std_logic_vector(31 downto 0);
    signal data_out_lati_reg : std_logic_vector(31 downto 0);
    signal data_out_long_reg : std_logic_vector(31 downto 0);
	
--------------------------------------------------------------------------------
--enable signal used to send lagitude and longitude
--------------------------------------------------------------------------------
    signal  data_out_ready1 :   std_logic;      --used to create tick signal
    signal  data_out_ready2 :   std_logic;
    signal  s_data_out_ready    :   std_logic;  --for probe can not connect to port

begin
--predefine lati (33249248) and long (97146411)
    DATA_LATI_CHECK <= conv_std_logic_vector(LATI, 32); --33249248
    DATA_LONG_CHECK <= conv_std_logic_vector(LONG, 32); --97146411

--    ILA_ila_GPS : ila_GPS
--    port map (
--        clk => clk2,
--        probe0(0)  => s_data_out_ready,
--        probe1  => lati_word(0),
--        probe2  => lati_word(1),
--        probe3  => lati_word(2),
--        probe4  => lati_word(3),
--        probe5  => lati_word(4),
--        probe6  => lati_word(5),
--        probe7  => lati_word(6),
--        probe8  => lati_word(7),
--        probe9  => lati_word(8),
--        probe10 => lati_word(9),
--        probe11 => lati_word(10),
--        probe12 => lati_word(11),
--        probe13 => data_lati,
--        probe14 => data_long
--        );
        
--------------------------------------------------------------------------------
--predefine the value of correct_word
--------------------------------------------------------------------------------
    correct_word(0) <= x"47";    --G
    correct_word(1) <= x"50";    --P
    correct_word(2) <= x"47";    --G
    correct_word(3) <= x"47";    --G
    correct_word(4) <= x"41";    --A
    correct_word(5) <= x"2C";    --,
--------------------------------------------------------------------------------
--save the first 6 correct byte and compare with correct_word
--------------------------------------------------------------------------------
	 save_corr : process(clk, rst)
	 begin
		if (rst = '1') then			
			cnt_corr <= (others => '0');
			for i in CMD_DEPTH-1 downto 0 loop
				input_word(i) <= (others => '0');
			end loop;
			comp <= '0';
			comma_cnt_en <= '0';
		elsif (clk'event and clk = '1') then
			if (data_in_en = '1') then
				if (data_in = x"24") then                   --when meet '$', clear the input_word
			        for i in CMD_DEPTH-1 downto 0 loop
                         input_word(i) <= (others => '0');
                    end loop;		
                    cnt_corr <= (others=>'0');              --when meet '$', clear the cnt_corr		      
					comp <= '0';
				else
				    if (cnt_corr < CMD_DEPTH) then
				        cnt_corr <= cnt_corr+1;
				        input_word(conv_integer(cnt_corr)) <= data_in;
				        comp <= '0';
                    else    --when cnt_corr = 6, compare input_word with correct word
                        comp <= '1';
                        cnt_corr <= cnt_corr;
                    end if;
				end if;  
			end if;
				
            if (comp = '1') then    --when (clk'event and clk = '1'), so comma_cnt_en is one clk later than comp
                if (input_word = correct_word) then
                    comma_cnt_en <= '1';
                else
                    comma_cnt_en <= '0';
                end if;
            else    --when comp = '0'
                comma_cnt_en <= '0';
            end if;
        end if;			
	 end process;		 		
--------------------------------------------------------------------------------
-- cnt the number of parse
-- by counting the number of comma to locate the lang and lati
--------------------------------------------------------------------------------			
    comma_count : process(clk, rst)
    begin
        if (rst = '1') then
            cnt_comma <= (others => '0');   --the cnt_comma must be clear in some other where, but where???
            lati_en <= '0';
            long_en <= '0';
            lati_ready <= '0';
            long_ready <= '0';
        elsif (clk'event and clk = '1') then
            if (comma_cnt_en = '1') then
                if (data_in_en = '1') then
                    if (data_in = x"24") then           --when gets '$', clear
                        cnt_comma <= (others => '0');
                        lati_en <= '0';
                        long_en <= '0';
                        lati_ready <= '0';
                        long_ready <= '0';         
                    elsif (data_in = x"2C") then        --when gets ','
                        if (cnt_comma = 5) then
                            cnt_comma <= cnt_comma;
                            lati_ready <= '1';
                            long_ready <= '1';
                        else
                            cnt_comma <= cnt_comma + 1;
                            if (cnt_comma = 0) then
                                lati_en <= '1';
                                long_en <= '0';
                                lati_ready <= '0';
                                long_ready <= '0';
                            elsif (cnt_comma = 1) then
                                lati_en <= '0';
                                long_en <= '0';
                                lati_ready <= '1';
                                long_ready <= '0';
                            elsif (cnt_comma = 2) then
                                lati_en <= '0';
                                long_en <= '1';
                                lati_ready <= '1';
                                long_ready <= '0';
                            elsif (cnt_comma = 3) then
                                lati_en <= '0';
                                long_en <= '0';
                                lati_ready <= '1';
                                long_ready <= '1';
                            else
                                lati_en <= '0';
                                long_en <= '0';
                                lati_ready <= '1';
                                long_ready <= '1';
                            end if;
                        end if;
                    else
                        cnt_comma <= cnt_comma;
                    end if;
                end if;
            end if; 
        end if;                     
    end process;
	
--------------------------------------------------------------------------------
--get Latitude and Longitude
--------------------------------------------------------------------------------
data_lati_l1 <= data_lati(30 downto 0) & '0';
data_lati_l3 <= data_lati(28 downto 0) & "000";
data_lati_reg <= x"00000000" when cnt_lati = 4 or data_in = x"24" else
                 x"0000000" & data_in(3 downto 0); 
                    
data_long_l1 <= data_long(30 downto 0) & '0';
data_long_l3 <= data_long(28 downto 0) & "000";
data_long_reg <= x"00000000" when cnt_long = 5 or data_in = x"24" else
                 x"0000000" & data_in(3 downto 0);

    extract : process(clk, rst)
    begin
        if (rst = '1') then
            cnt_lati <= (others => '0');
            cnt_long <= (others => '0');
             
            for i in ARRAY_DEPTH-1 downto 0 loop
                lati_word(i) <= (others => '0');    --unextracted data
            end loop;
            for i in ARRAY_DEPTH-1 downto 0 loop
                long_word(i) <= (others => '0');
            end loop;
                     
            data_lati <= (others => '0');       --extracted data, 32 bits
            data_long <= (others => '0'); 

        elsif (clk'event and clk = '1') then
            if (data_in_en = '1') then
                if (data_in = x"24") then               --when gets '$', clear
                    cnt_lati <= (others => '0');
                    cnt_long <= (others => '0');                   
                    for i in ARRAY_DEPTH-1 downto 0 loop
                        lati_word(i) <= (others => '0');
                    end loop;
                    for i in ARRAY_DEPTH-1 downto 0 loop
                        long_word(i) <= (others => '0');
                    end loop;
                    
                    data_lati       <= (others => '0'); 
                    data_long       <= (others => '0'); 
                end if;

--latidute               
                if (lati_en = '1' and data_in = x"2c") then	--data_in = ','
                    cnt_lati <= (others => '0');
                elsif (lati_en = '1') then
                    cnt_lati <= cnt_lati + 1;
                     --save unextracted data into array
                    if (cnt_lati = ARRAY_DEPTH) then
                        cnt_lati <= cnt_lati;
                    else
                        lati_word(conv_integer(cnt_lati)) <= data_in;
                    end if;
                    --extract datas from data_in
                    if (cnt_lati = 0) then
                        data_lati <= data_lati(31 downto 4) & data_in(3 downto 0);
                    elsif (cnt_lati = 4) then
                        data_lati <= data_lati;
                    else
                        data_lati <= data_lati_l1 + data_lati_l3 + data_lati_reg;
                    end if; 
                end if; 
--longitude
                if (long_en = '1' and data_in = x"2c") then
                    cnt_long <= (others => '0');
                elsif (long_en = '1') then
                    cnt_long <= cnt_long + 1;
                    --save unextracted data into array
                    if (cnt_long = ARRAY_DEPTH) then
                        cnt_long <= cnt_long;
                    else
                        long_word(conv_integer(cnt_long)) <= data_in;
                    end if;
                    --extract datas from data_in
                    if (cnt_long = 0) then
                        data_long <= data_long(31 downto 4) & data_in(3 downto 0);
                    elsif (cnt_long = 5) then
                        data_long <= data_long;
                    else
                        data_long <= data_long_l1 + data_long_l3 + data_long_reg;
                    end if;
                end if;
            end if;
        end if;                    
    end process;
    
--------------------------------------------------------------------------------
--send Latitude and Longitude
--------------------------------------------------------------------------------
    send_data : process(clk, rst)
    begin
        if (rst = '1') then          
            s_data_out_lati <= (others => '0');
            s_data_out_long <= (others => '0');
            err_lati_abs <= (others => '0');
            err_long_abs <= (others => '0');
        elsif (clk'event and clk = '1') then
            if (data_in_en = '1') then
                if (lati_ready = '1' and long_ready = '1') then
                    if (data_in = x"24") then
                        s_data_out_lati <= (others => '0');
                        s_data_out_long <= (others => '0');
                    else
                        s_data_out_lati <= data_lati;
                        s_data_out_long <= data_long;                        
                    end if;
                    
                    err_lati <= s_data_out_lati - DATA_LATI_CHECK;
                    err_long <= s_data_out_long - DATA_LONG_CHECK;
                    
                    if (err_lati(31) = '0') then
                        err_lati_abs <= err_lati;
                    else
                        err_lati_abs <= not(err_lati) + 1;
                    end if;
                    if (err_long(31) = '0') then
                        err_long_abs <= err_long;
                    else
                        err_long_abs <= not(err_long) + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
-----------------------------
--check
----------------------------
    check : process(clk, rst)
    begin
        if (rst = '1') then
            data_out_lati <= (others => '0');
            data_out_long <= (others => '0');
            data_out_ready1 <= '0';
        elsif (clk'event and clk = '1') then
            if (data_in_en = '1') then
                if (lati_ready = '1' and long_ready = '1') then
                    if ((err_lati_abs < 100000) and (err_long_abs < 100000)) then
                        data_out_ready1 <= '1';
                        data_out_lati <= data_lati;
                        data_out_long <= data_long;
                        data_out_lati_reg <= data_lati;
                        data_out_long_reg <= data_long;
                    else
                        data_out_ready1 <= '0';
                        data_out_lati <= data_out_lati_reg;
                        data_out_long <= data_out_long_reg;
                    end if;
                end if;
            end if;
        end if;
    end process;

    
    tick : process(clk, rst)
    begin
        if (rst = '1') then
            data_out_ready2 <= '0';
            data_out_ready <= '0';
            s_data_out_ready <= '0';
        elsif (clk'event and clk = '1') then
            data_out_ready2 <= data_out_ready1;
            if (data_out_ready1 = '1' and data_out_ready2 = '0') then
                data_out_ready <= '1';
                s_data_out_ready <= '1';
            else
                data_out_ready <= '0';
                s_data_out_ready <= '0';
            end if;
        end if;       
    end process;    
	 
end Behavioral;
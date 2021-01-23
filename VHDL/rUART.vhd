library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity rUART is
    --  Generic ( );
    generic(
        clk_rate : integer := 100e6;
        baud     : integer := 115200
    );
    --  Port ( );
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;
        Rx         : in  std_logic;
        data_valid : out std_logic;
        data_out   : out std_logic_vector(7 downto 0)
    );
end rUART;

architecture rtl of rUART is

    -- Declarative zone of VHDL
    
    -- Finite state machine
    type state_type is (idle, start, send_data, stop);
    signal state : state_type := idle;
    
    constant max_value_baud : integer := clk_rate / baud;
    signal max_counter_baud : integer range 0 to max_value_baud - 1 := 0;
    signal bit_number       : integer range 0 to 7 := 0;
    
    signal data_out_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid_reg : std_logic := '0';

begin
    
    -- Out signal assigments
    data_out   <= data_out_reg;
    data_valid <= data_valid_reg;
    

    fsm_proc: process(clk) is
    begin
        if rising_edge(clk) then
            if ( reset = '0') then
                state <= idle;
            else
            
                case state is
                
                    when idle      =>
                        max_counter_baud <= 0;
                        bit_number       <= 0;
                        data_valid_reg   <= '0';
                    
                        if (Rx = '0') then
                            state <= start;
                        else
                            state <= idle;
                        end if;
                    
                    -- We need to wait (max_counter_baud - 1) / 2 to be sure that is the start bit
                    when start     => -- Start bit detection
                        if (max_counter_baud = (max_value_baud - 1) / 2) then
                            if (Rx = '0') then
                                max_counter_baud <= 0; -- Reset counter becasue we find the start bit
                                state            <= send_data; -- Go to send data state
                            else
                                state            <= idle;
                            end if;
                        else
                            max_counter_baud <= max_counter_baud + 1;
                            state            <= start;
                        end if;
                    
                    when send_data => -- From serial data to paralell
                        if (max_counter_baud < max_value_baud - 1) then
                            state            <= send_data;
                            max_counter_baud <= max_counter_baud + 1;
                        else
                            data_out_reg(bit_number) <= Rx;
                            max_counter_baud         <= 0;                    
                            if (bit_number) < 7 then
                                bit_number <= bit_number + 1;
                                state      <= send_data;
                            else
                                bit_number <= 0;
                                state      <= stop;
                            end if;
                        end if;
                    
                    -- wait max_value_baud - 1 ticks for stop bit
                    when stop      => -- Receive stop bit. stop bit = 1
                        if (max_counter_baud < max_value_baud - 1) then
                            state            <= stop;
                            max_counter_baud <= max_counter_baud + 1;
                        else
                            state            <= idle;
                            data_valid_reg   <= '1';
                            max_counter_baud <= 0;
                        end if;
                        
                    when others      =>
                        state <= idle;
                
                end case;
            end if;
        end if;
    end process fsm_proc;


end rtl;

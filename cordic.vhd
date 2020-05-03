library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all;

entity cordic is
port (
    clock : in std_logic;
    reset : in std_logic;
    in_dout : in std_logic_vector (31 downto 0);
    in_rd_en : out std_logic;
    in_empty : in std_logic;
    out_cos_wr_en : out std_logic;
    out_cos_din : out std_logic_vector (31 downto 0);
    out_cos_full : in std_logic;
    out_sin_wr_en : out std_logic;
    out_sin_din : out std_logic_vector (31 downto 0);
    out_sin_full : in std_logic
);
end entity cordic;

architecture behavior of cordic is

    type state_type is (s0, s1, s2);
    signal state, next_state : state_type := s0;
    signal out_cos_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal out_cos_rd_en : std_logic := '0';
    signal out_cos_empty : std_logic := '0';
    signal out_sin_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal out_sin_rd_en : std_logic := '0';
    signal out_sin_empty : std_logic := '0';
    signal done, done_c : integer := 0;
    signal start, start_c : integer := 0;
    type pipeline_array is array (0 to 15) of std_logic_vector (31 downto 0);
    signal x_in, y_in, z_in : pipeline_array := (others => (others => '0'));
    signal x_out, y_out, z_out : pipeline_array := (others => (others => '0'));
    signal x_in_c, y_in_c, z_in_c : pipeline_array := (others => (others => '0'));
    signal Angle, Angle_c : std_logic_vector(31 downto 0) := (others => '0');	
	
    type atan_table_lut is array (0 to 15) of std_logic_vector (15 downto 0);
    signal CORDIC_TABLE : atan_table_lut := (x"3243", x"1DAC", x"0FAD", x"07F5", x"03FE", x"01FF", x"00FF", x"007F", 
											 x"003F", x"001F", x"000F", x"0007", x"0003", x"0001", x"0000", x"0000");
    
begin

	-- Creates 16 pipelined stages -- 
    pipelined_stages_gen : for i in 0 to N_STAGES - 1 generate   
        cordic_stage_n : cordic_stage
        port map (
            i => i,
            atan => CORDIC_TABLE(i),
            x_i => x_in(i),
            y_i => y_in(i),
            z_i => z_in(i),
            x_o => x_out(i),
            y_o => y_out(i),
            z_o => z_out(i)
        );
    end generate pipelined_stages_gen;

    fsm_process : process (state, in_empty, out_cos_full, out_sin_full, in_dout, x_out, y_out, z_out, Angle, done, start)
        variable Angle_t : integer := 0;
    begin
        in_rd_en <= '0';
        out_cos_wr_en <= '0';
        out_sin_wr_en <= '0';
        out_cos_din <= (others => '0');
        out_sin_din <= (others => '0');
        next_state <= state;
        x_in_c <= x_in;
        y_in_c <= y_in;
        z_in_c <= z_in;
        Angle_c <= Angle;
        done_c <= done;
        start_c <= start;

        case (state) is 

            when s0 =>
                if (in_empty = '0') then
                    in_rd_en <= '1';
                    Angle_c <= in_dout;
                    next_state <= s1;
                elsif (start >= DATA_LENGTH - (N_STAGES - 1)) then
                    next_state <= s1;
                end if;
                x_in_c(0) <= K;
            when s1 =>
                Angle_t := to_integer(signed(Angle));
                if (Angle_t > PI) then
                    Angle_c <= std_logic_vector(signed(Angle) - to_signed(TWO_PI, 32));
                elsif (Angle_t < NEG_PI) then
                    Angle_c <= std_logic_vector(signed(Angle) + to_signed(TWO_PI, 32));
                elsif (Angle_t > PI_OVER_TWO) then
                    Angle_c <= std_logic_vector(signed(Angle) - to_signed(PI, 32));
                    x_in_c(0) <= std_logic_vector(not(signed(x_in(0))) + to_signed(1, 32)); 
                elsif (Angle_t < NEG_PI_OVER_TWO) then
                    Angle_c <= std_logic_vector(signed(Angle) + to_signed(PI, 32));
                    x_in_c(0) <= std_logic_vector( not(signed(x_in(0))) + to_signed(1, 32));
                else
                    next_state <= s2;
                    z_in_c(0) <= Angle;
                end if;
            when s2 =>
                for i in 0 to N_STAGES - 2 loop
                    x_in_c(i + 1) <= x_out(i);
                    y_in_c(i + 1) <= y_out(i);
                    z_in_c(i + 1) <= z_out(i);
                end loop;
                if (done < N_STAGES - 1) then
                    done_c <= done + 1;
                elsif (out_cos_full = '0' and out_sin_full = '0') then
                    out_cos_wr_en <= '1';
                    out_sin_wr_en <= '1';
                    out_cos_din <= x_out(N_STAGES - 1);
                    out_sin_din <= y_out(N_STAGES - 1);
                end if;
                start_c <= start + 1;
                next_state <= s0;
        end case;     
    end process;
	
	clock_process : process (clock, reset)
    begin
        if reset = '1' then
            state <= s0;
            x_in <= (others => (others => '0'));
            y_in <= (others => (others => '0'));
            z_in <= (others => (others => '0'));
            Angle <= (others => '0');
            done <= 0;
            start <= 0;
        elsif rising_edge(clock) then 
            state <= next_state;
            x_in <= x_in_c;
            y_in <= y_in_c;
            z_in <= z_in_c;
            Angle <= Angle_c;
            done <= done_c;
            start <= start_c;
        end if;
    end process;
	
end architecture behavior;
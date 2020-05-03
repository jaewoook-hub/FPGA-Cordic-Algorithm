library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all;

entity cordic_top is
port (
    clock : in std_logic;
    reset : in std_logic;
    in_din : in std_logic_vector (31 downto 0);
    in_wr_en : in std_logic;
    in_full : out std_logic;
    out_cos_rd_en : in std_logic;
    out_cos_dout : out std_logic_vector (31 downto 0);
    out_cos_empty : out std_logic;
    out_sin_rd_en : in std_logic;
    out_sin_dout : out std_logic_vector (31 downto 0);
    out_sin_empty : out std_logic
);
end entity cordic_top;

architecture behavior of cordic_top is
    signal in_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal in_rd_en : std_logic := '0';
    signal in_empty : std_logic := '0';
    signal out_cos_din : std_logic_vector (31 downto 0) := (others => '0');
    signal out_cos_wr_en : std_logic := '0';
    signal out_cos_full : std_logic := '0';
    signal out_sin_din : std_logic_vector (31 downto 0) := (others => '0');
    signal out_sin_wr_en : std_logic := '0';
    signal out_sin_full : std_logic := '0';

begin

    fifo_in : fifo
	generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => 16
    )
    port map (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => in_rd_en,
        wr_en => in_wr_en,
        din => in_din,
        dout => in_dout,
        full => in_full,
        empty => in_empty
    );

    cordic_inst : cordic
    port map (
        clock => clock,
        reset => reset,
        in_dout => in_dout,
        in_rd_en => in_rd_en,
        in_empty => in_empty,
        out_cos_wr_en => out_cos_wr_en,
        out_cos_din => out_cos_din,
        out_cos_full => out_cos_full,
        out_sin_wr_en => out_sin_wr_en,
        out_sin_din => out_sin_din,
        out_sin_full => out_sin_full
    );

    fifo_out_cos : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => 16
    )
    port map (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => out_cos_rd_en,
        wr_en => out_cos_wr_en,
        din => out_cos_din,
        dout => out_cos_dout,
        full => out_cos_full,
        empty => out_cos_empty
    );

    fifo_out_sin : fifo 
    generic map (
        FIFO_DATA_WIDTH => 32,
        FIFO_BUFFER_SIZE => 16
    )
    port map (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => out_sin_rd_en,
        wr_en => out_sin_wr_en,
        din => out_sin_din,
        dout => out_sin_dout,
        full => out_sin_full,
        empty => out_sin_empty
    );

end architecture behavior;
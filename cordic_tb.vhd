library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use IEEE.math_real.all;
use IEEE.math_complex.all;
use work.constants.all;

entity cordic_tb is
generic (
    constant SIN_OUT : string (11 downto 1) := "sin_out.txt";
    constant COS_OUT : string (11 downto 1) := "cos_out.txt";
    constant COS_ACTUAL : string (14 downto 1) := "cos_actual.txt";
    constant SIN_ACTUAL : string (14 downto 1) := "sin_actual.txt";
    constant SIN_CMP : string (7 downto 1) := "sin.txt";
    constant COS_CMP : string (7 downto 1) := "cos.txt";
    constant COS_DIFF : string (12 downto 1) := "cos_diff.txt";
    constant SIN_DIFF : string (12 downto 1) := "sin_diff.txt";
    constant CLOCK_PERIOD : time := 10 ns
);
end entity cordic_tb;

architecture behavior of cordic_tb is

    function to_slv(c : character) return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(character'pos(c),8));
        end function to_slv;
        
    function to_char(v : std_logic_vector) return character is
    begin
        return character'val(to_integer(unsigned(v)));
    end function to_char;

    function sra_func( val : signed; n : integer )
    return signed is
        variable temp : signed (val'length - 1 downto 0);
    begin
        temp := val srl n;
        temp(val'length - 1 downto val'length - n) := (others => val(val'length - 1));
        return temp;
    end function sra_func; 

    function quantize_n( val : integer; n : integer )
    return signed is
        variable temp : signed (63 downto 0);
    begin
        temp := to_signed(val, 64) sll n;
        return temp;
    end function;

    signal clock : std_logic := '1';
    signal reset : std_logic := '0';
    signal hold_clock : std_logic := '0';
    signal in_write_done : std_logic := '0';
    signal out_read_done : std_logic := '0';
    signal cos_errorors, sin_errorors : integer := 0;
    signal in_wr_en : std_logic := '0';
    signal in_full : std_logic := '0';
    signal in_din : std_logic_vector (31 downto 0) := (others => '0');
    signal out_cos_rd_en : std_logic := '0';
    signal out_cos_empty : std_logic := '0';
    signal out_cos_dout : std_logic_vector (31 downto 0) := (others => '0');
    signal out_sin_rd_en : std_logic := '0';
    signal out_sin_empty : std_logic := '0';
    signal out_sin_dout : std_logic_vector (31 downto 0) := (others => '0');

    begin

    cordic_top_inst : cordic_top 
    port map (
        clock => clock,
        reset => reset,
        in_din => in_din,
        in_wr_en => in_wr_en,
        in_full => in_full,
        out_cos_rd_en => out_cos_rd_en,
        out_cos_dout => out_cos_dout,
        out_cos_empty => out_cos_empty,
        out_sin_rd_en => out_sin_rd_en,
        out_sin_dout => out_sin_dout,
        out_sin_empty => out_sin_empty
    );

    clock_process : process
    begin
        clock <= '1';
        wait for  (CLOCK_PERIOD / 2);
        clock <= '0';
        wait for  (CLOCK_PERIOD / 2);
        if ( hold_clock = '1' ) then
            wait;
        end if;
    end process clock_process;

    reset_process : process
    begin
        reset <= '0';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '1';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '0';
        wait;
    end process reset_process;

    file_read_process : process 
        variable ln1 : line;
        variable i : integer := -360;
    begin
        wait until (reset = '1');
        wait until (reset = '0');
        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Reading into input FIFO...") );
        writeline( output, ln1 );
        in_wr_en <= '0';
        while (i <= 360) loop
            if (in_full = '0') then
                in_wr_en <= '1';
                in_din <=  std_logic_vector(resize(sra_func(((((quantize_n(i, 14) sll 14) + quantize_n(180, 13)) / quantize_n(180, 14)) * to_signed(PI, 64)) + quantize_n(1, 13), 14), 32));
                i := i + 1;
            else
                in_wr_en <= '0';
            end if; 
            wait until (clock = '1');
            wait until (clock = '0');
        end loop;
        wait until (clock = '1');
        wait until (clock = '0');
        in_wr_en <= '0';
        in_write_done <= '1';
        wait;
    end process file_read_process; 

    file_write_process : process 
        file cos_out_file, sin_out_file : text;
        file cos_cmp_file, sin_cmp_file : text;
        file cos_diff_file, sin_diff_file : text;
        file cos_actual_file, sin_actual_file : text;
        variable ln1, ln2, ln3, ln4, ln5, ln6, ln7, ln8, ln9 : line;
        variable i : integer := 0;
        variable cos_cmp_data : std_logic_vector (31 downto 0);
        variable sin_cmp_data : std_logic_vector (31 downto 0);
        variable actual_cos : real;
        variable actual_sin : real;
        variable cos_actual_var : real;
        variable sin_actual_var : real;
        variable angle : integer := -360;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');
        wait until  (clock = '1');
        wait until  (clock = '0');

        file_open(cos_diff_file, COS_DIFF, write_mode);
        file_open(sin_diff_file, SIN_DIFF, write_mode);
        file_open(cos_out_file, COS_OUT, write_mode);
        file_open(sin_out_file, SIN_OUT, write_mode);
        file_open(cos_cmp_file, COS_CMP, read_mode);
        file_open(sin_cmp_file, SIN_CMP, read_mode);
        file_open(cos_actual_file, COS_ACTUAL, read_mode);
        file_open(sin_actual_file, SIN_ACTUAL, read_mode);

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Comparing files ") );
        write( ln1, COS_OUT );
        write( ln1, string'(" and ") );
        write( ln1, SIN_OUT );
        write( ln1, string'("...") );
        writeline( output, ln1 );

        out_cos_rd_en <= '0';
        out_sin_rd_en <= '0';

		while ( (not ENDFILE(cos_cmp_file)) ) loop
			wait until ( clock = '1');
            wait until ( clock = '0');
            if ( out_cos_empty = '0' or out_sin_empty = '0') then
                out_cos_rd_en <= '1';
                hwrite( ln2, out_cos_dout );
                writeline( cos_out_file, ln2 );
                out_sin_rd_en <= '1';
                hwrite( ln3, out_sin_dout );
                writeline( sin_out_file, ln3 );
                readline(cos_cmp_file, ln4);
                hread(ln4, cos_cmp_data);
                readline(sin_cmp_file, ln5);
                hread(ln5, sin_cmp_data);
                actual_cos := real(to_integer(signed(out_cos_dout))) / real(QUANT_VAL_INT);
                actual_sin := real(to_integer(signed(out_sin_dout))) / real(QUANT_VAL_INT);
                readline(cos_actual_file, ln8);
                read(ln8, cos_actual_var);
                readline(sin_actual_file, ln9);
                read(ln9, sin_actual_var);
                write( ln6, actual_cos - cos_actual_var );
                writeline(COS_DIFF_file, ln6);
                write( ln7, actual_sin - sin_actual_var );
                writeline(SIN_DIFF_file, ln7);

                if ( to_01(unsigned(out_cos_dout)) /= to_01(unsigned(cos_cmp_data)) ) then
                    cos_errorors <= cos_errorors + 1;
                    write( ln2, string'("@ ") );
                    write( ln2, NOW );
                    write( ln2, string'(": ") );
                    write( ln2, COS_OUT );
                    write( ln2, string'("(") );
                    write( ln2, i + 1 );
                    write( ln2, string'("): DIFFERENCE IN COS: ") );
                    hwrite( ln2, out_cos_dout );
                    write( ln2, string'(" COMPARED TO ") );
                    hwrite( ln2, cos_cmp_data);
                    write( ln2, string'(" at address 0x") );
                    hwrite( ln2, std_logic_vector(to_unsigned(i,32)) );
                    write( ln2, string'(".") );
                    writeline( output, ln2 );
                end if;

                if ( to_01(unsigned(out_sin_dout)) /= to_01(unsigned(sin_cmp_data)) ) then
                    sin_errorors <= sin_errorors + 1;
                    write( ln2, string'("@ ") );
                    write( ln2, NOW );
                    write( ln2, string'(": ") );
                    write( ln2, SIN_OUT );
                    write( ln2, string'("(") );
                    write( ln2, i + 1 );
                    write( ln2, string'("): DIFFERENCE IN SIN: ") );
                    hwrite( ln2, out_sin_dout );
                    write( ln2, string'(" COMPARED TO ") );
                    hwrite( ln2, sin_cmp_data);
                    write( ln2, string'(" at address 0x") );
                    hwrite( ln2, std_logic_vector(to_unsigned(i,32)) );
                    write( ln2, string'(".") );
                    writeline( output, ln2 );
                end if;
                i := i + 1;
                angle := angle + 1;
            else
                out_cos_rd_en <= '0';
                out_sin_rd_en <= '0';
            end if;
        end loop;
        wait until  (clock = '1');
        wait until  (clock = '0');
        out_cos_rd_en <= '0';
        out_sin_rd_en <= '0';
        file_close( cos_out_file );
        file_close( sin_out_file );
        out_read_done <= '1';
        wait;
    end process file_write_process;

    tb_proc : process
        variable cos_error, sin_error : integer := 0;
        variable warnings : integer := 0;
        variable start_time : time;
        variable end_time : time;
        variable ln1, ln2, ln3, ln4, ln5 : line;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');
        wait until  (clock = '0');
        wait until  (clock = '1');
        start_time := NOW;
        write( ln1, string'("@ ") );
        write( ln1, start_time );
        write( ln1, string'(": Beginning simulation...") );
        writeline( output, ln1 );
        wait until  (clock = '0');
        wait until  (clock = '1');
        wait until (out_read_done = '1');
        end_time := NOW;
        write( ln2, string'("@ ") );
        write( ln2, end_time );
        write( ln2, string'(": Simulation completed.") );
        writeline( output, ln2 );
        sin_error := sin_errorors;
        cos_error := cos_errorors;
        write( ln3, string'("Total simulation cycle count: ") );
        write( ln3, (end_time - start_time) / CLOCK_PERIOD );
        writeline( output, ln3 );
        write( ln4, string'("Total cos error count: ") );
        write( ln4, cos_error );
        writeline( output, ln4 );
        write( ln5, string'("Total sin error count: ") );
        write( ln5, sin_error );
        writeline( output, ln5 );
        hold_clock <= '1';
        wait;
    end process tb_proc;

end architecture behavior;

`timescale 1ns/1ps
module test;
reg keyoff, ksr, attack, cnt_in;
reg [2:0] state;
reg [3:0] rr, keycode;
reg [4:0] base;
reg [14:0] counter;
reg [9:0] level;
wire [4:0] selected;
wire [2:0] next_state;
wire pg_rst, cnt_lsb, step, sum_up;
wire [5:0] rate;
wire [9:0] result;
integer r, k, mode, expected, i, total, target, test_rate;

jtopl_eg_ctrl ctrl(.keyon_now(1'b0), .keyoff_now(keyoff), .state_in(state),
    .eg(10'd0), .en_sus(1'b0), .arate(4'd0), .drate(4'd0), .rrate(rr),
    .sl(4'd15), .base_rate(selected), .state_next(next_state), .pg_rst(pg_rst));
jtopl_eg_step stepper(.attack(attack), .base_rate(base), .keycode(keycode),
    .eg_cnt(counter), .cnt_in(cnt_in), .ksr(ksr), .cnt_lsb(cnt_lsb),
    .step(step), .rate(rate), .sum_up(sum_up));
jtopl_eg_pure u_pure(.attack(attack), .step(step), .rate(rate[5:1]),
    .eg_in(level), .sum_up(sum_up), .eg_pure(result));
initial begin
    $dumpfile("test.lxt"); $dumpvars;
    keyoff=0; state=0; rr=0; base=0; keycode=0; ksr=0; attack=0;
    counter=0; cnt_in=0; level=0;
    for (r=0; r<16; r=r+1) begin
        rr=r; #1;
        if (selected !== r*2 || next_state !== 0) $fatal(1,"release rate %0d",r);
        keyoff=1; state=2; #1;
        if (selected !== r*2 || next_state !== 0) $fatal(1,"keyoff rate %0d",r);
        keyoff=0; state=0;
        for (k=0; k<16; k=k+1) for (mode=0; mode<2; mode=mode+1) begin
            base=r*2; keycode=k; ksr=mode; #1;
            expected = r==0 ? 0 : r*4+(mode ? k : (k>>2));
            if (expected>=60) expected=63;
            if (rate !== expected) $fatal(1,"rate rr=%0d key=%0d ksr=%0d got=%0d expected=%0d",r,k,mode,rate,expected);
        end
    end
    // A full counter period checks low-rate step patterns, including the
    // rates used by the measured decay and release examples in the issue.
    for (test_rate=12; test_rate<=47; test_rate=test_rate+1) begin
        base=(test_rate/4)*2; keycode=test_rate%4; ksr=1;
        cnt_in=1; total=0;
        for (i=0; i<32768; i=i+1) begin
            counter=i; level=100; #1;
            total=total+result-100;
            cnt_in=cnt_lsb;
        end
        target=(4+(test_rate%4)) << ((test_rate/4)+1);
        if (total != target) $fatal(1,"slow rate %0d total=%0d expected=%0d",test_rate,total,target);
    end
    // Eight samples contain the four reference increments twice. Each OPL
    // attenuation step is two internal units, and updates occur every other sample.
    for (test_rate=48; test_rate<64; test_rate=test_rate+1) begin
        base=(test_rate/4)*2; keycode=test_rate%4; ksr=1;
        cnt_in=1; total=0;
        for (i=0; i<8; i=i+1) begin
            counter=i; level=100; #1;
            total=total+result-100;
            cnt_in=cnt_lsb;
        end
        target = test_rate>=60 ? 64 : (8+2*(test_rate%4)) << ((test_rate/4)-12);
        if (total != target) $fatal(1,"fast rate %0d total=%0d expected=%0d",test_rate,total,target);
    end
    // Saturation and the update gate must work for fast decay too.
    base=30; keycode=0; counter=0; cnt_in=0; level=1020; #1;
    if(result !== 1020) $fatal(1,"update gate");
    cnt_in=1; #1;
    if(result !== 1023) $fatal(1,"saturation");
    $display("PASS"); $finish;
end
endmodule

module counterTBK;

reg clk,gate,DE;
reg [5:0] contWord;
reg [7:0] dataIn;
wire out;
wire newCountF;
wire [15:0] countReg;
wire[15:0] currentCount;
wire [1:0]curr;
wire [1:0] next;
wire gateFlag1;
wire gateFlag2;
countInt fullCounter(clk,contWord,gate,dataIn,DE,out,countReg,currentCount,curr,next,newCountF,gateFlag1,gateFlag2);

initial begin
$monitor("%g\t controlWord:%b, dataIn:%b, dataEnable:%b, gate:%b, out:%b, counterReg:%b",$time,contWord,dataIn,DE,gate,out,countReg,currentCount,curr,next,newCountF,gateFlag1,gateFlag2);

clk=1'b0;

#20

contWord=6'b010100;

#10

dataIn=8'b00001111;

#10

DE=1;

#10

DE=0;

#10

gate=1;



dataIn=8'b00011111;

#20

DE=1;

#10

DE=0;

#20

#500;

$finish;

end

always begin #5 clk=~clk;
end		

endmodule

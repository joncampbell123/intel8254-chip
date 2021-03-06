module countInt(
input wire clk,
input wire[5:0] controlWord,    //7etet badawy
input wire gate,			//A Gate .... 
input reg [7:0] countIn,   	//8 bits LSB + 8bits of MSB
input wire dataEn,		//Enable to read the data
output reg out
);


// Incase we are using mode 1 or mode 2 where the count must be pipelined

reg[15:0] activeCount;
reg[15:0] currentCount;

reg mode0countDone=0;
reg mode1countDone=0;
reg[1:0] mode;

reg [1:0] currentState=2'b00;
reg [1:0] nextState=2'b00;

reg newCount=0;		//If a new count arrived
reg newCountFlag=0;	//To propagate the new count by 1 clock cycle	
	
reg [1:0]LM=0;		//LSB then MSB if ==1
reg lmFlag=0; 		//In case we used LSB then MSB (LM==11)


reg counting=0;        //Counting or finished counting

reg gateFlag1=0;       //For handling mode 1 and mode 2
reg gateFlag2=0;       //

// Bits 5,4===> Data in form, Bits 3,2,1 Mode (Bit 3 is redundant since we will use only 3 modes)  Bit 0 is redundant since we will always used Binary mode

always @(controlWord) begin

	mode0countDone=0;
	mode1countDone=0;
	newCount=0;
	newCountFlag=0;
	lmFlag=0;
	counting=0;
	gateFlag1=0;
	gateFlag2=0;
	currentState = 0;
	nextState = 0;
	LM = controlWord[5:4];
	mode = controlWord[2:1];
end //EOA


always@(gate) begin
if (gate&&currentState==2) begin	//gate pulse occured
	gateFlag1=1;			//Will set variable to check after the next clk cycle
end

end //EOA


always@(negedge clk) begin

currentState =nextState;

if (newCount==1&&currentState!=2) begin					    //If a new count came we set the flag to check in the next clk pulse
	newCountFlag=1;
	newCount=0;
end

else if (newCountFlag==1)begin
	newCountFlag=0;
	counting=1;
end

else if(gateFlag1==1) begin		
	gateFlag2<=1;
	gateFlag1<=0;
end

else if(gateFlag2==1&&currentState==2'b10) begin
	activeCount=currentCount+1;
	counting=1;
	gateFlag2=0;
end

if (currentState==1) begin    //mode 0
	if (counting==0) begin
		if(mode0countDone==1)begin
			out = 1;
			mode0countDone = 1;		
		end

		else	out<=0;
	end
	
	else begin
		
		if (gate==1 && activeCount!=0)begin
			out = 0;
			activeCount = activeCount-1;
			counting=1;
		end


		if (activeCount==0)begin
		out = 1;
		counting = 0;
		mode0countDone = 1;
		end

	end 

nextState = 1;

end

else if (currentState == 2) begin		//mode 1

	if (counting == 0) begin
		if (mode1countDone==1) begin
			mode1countDone<=1;
			out=1;
		end
		else out = 0;
	end

	else begin
		if (activeCount != 0) begin
			out=0;
			activeCount = activeCount-1;
			counting=1;
		end
		
		if (activeCount == 0) begin
			out = 1;
			counting=0;
			mode1countDone=1;
		end
	end

nextState = 2;

end

else if (currentState==3) begin //mode 2

	if (counting==0) begin
		out=1'b1;
	end

	else begin

		if (gate==1 && activeCount!= 0) begin
			out=1;
			activeCount=activeCount-1;
			counting=1;
		end 
		if (gate==1 && activeCount==0) begin
			out=0;
			activeCount=currentCount;		
		end
		else if (gate==0)
			out=0;
	end
nextState=3;

end


end//EOA



always @(countIn) begin

if (lmFlag==1) begin
	currentCount[15:8]=countIn;
	lmFlag=0;
	newCount=1;
end

end //EOA


always @(newCountFlag) begin

if (newCountFlag==1) begin
	if (mode==0||mode==2) begin
		activeCount=currentCount;
		counting=1;
	end

end

newCountFlag<=0;

end //EOA


always @(dataEn, countIn)begin

if (dataEn==1) begin
	if (LM==1) begin 
		currentCount[15:8] = 8'b00000000;
		currentCount[7:0] = countIn;
		newCount = 1;
	end

	else if (LM==2) begin 
		currentCount[15:8]= countIn;
		currentCount[7:0]=8'b00000000;
		newCount<=1;
	end

	else if (LM==3&&lmFlag==0) begin
		lmFlag=1;
		currentCount[7:0]=countIn;
	end
end

end//EOA

always@(mode) begin	//Assuming mode will have a range of {0,1,2}

if (mode==0) begin
	nextState = 1;	//mode0
end

else if (mode==1) begin
	nextState = 2;	//mode1
end

else  begin
	nextState = 3;	//mode2
end

end//EOA

endmodule 
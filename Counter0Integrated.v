module countInt(
input wire clk,
input wire[5:0] controlWord,    //7etet badawy
input wire gate			//A Gate .... 
input reg [7:0] countIn,   	//8 bits LSB + 8bits of MSB
input wire dateEn		//Enable to read the data
output reg out
);
reg [15:0]currentCount;	  // Incase we are using mode 1 or mode 2 where the count must be pipelined
reg [15:0]activeCount;    // Since it will updated after the gate pulse by one clock cycle

wire[1:0] mode;
reg [1:0] currentState=2'b00;
reg [1:0] nextState=2'b00;

reg newCount=0;		//If a new count arrived
reg newCountFlag=0;	//To propagate the new count by 1 clock cycle	
	
reg [1:0]LM=0;		//LSB then MSB if ==1
reg lmFlag=0; 		//In case we used LSB then MSB (LM==11)


reg counting=0;        //Counting or finished counting

reg gateFlag1=0;       //For handling mode 1 and mode 2
reg gateFlag2=0;       //

// Bits 5,4===> Data in form , Bits 3,2,1 Mode (Bit 3 is redundant since we will use only 3 modes)  Bit 0 is redundant since we will always used Binary mode

always @(controlWord) begin

LM=controlWord[5:4];
mode=controlWord[2:1];

end //EOA



always@(posedge clk) begin

currentState <=nextState;

if (currentState==0) out=1'bz;                              //Floating

if (newCount==1) begin					    //If a new count came we set the flag to check in the next clk pulse
	newCountFlag=1;
	newCount=0;
end

else if (newCountFlag==1)begin
	newCountFlag=0;
	counting=1;
end

if (gate&&mode==1) begin		//gate pulse occured
	gateFlag1=1;			//Will set variable to check after the next clk cycle
end

else if (gate&&mode==2) begin		//Same as above lines
	gateFlag1=1;
end

else if(gateFlag1==1) begin		
	gateFlag2=1;
end


end//EOA



always @(countIn) begin

if (lmFlag==1) begin
	currentCount[15:8]<=countIn;
	lmFlag=0;
	newCount=1;
end

end //EOA


always @(newCountFlag) begin

if (newCountFlag==1) begin
	if (mode==0) begin
		activeCount<=currentCount;
	end

	if (mode==1||mode==2) begin	
		if (gateFlag2)
			activeCount<=currentCount;
	end

end

newCountFlag<=0;

end //EOA


always@(posedge dataEn)begin

if (LM==1) begin 
	currentCount[15:8]<=8'b00000000;
	currentCount[7:0]<= countIn;
	newCount<=1;
end

else if (LM==2) begin 
	currentCount[15:8]<= countIn;
	currentCount[7:0]<=8'b00000000;
	newCount<=1;
end

else if (LM==3&&lmFlag==0) begin
	lmFlag=1;
	currentCount[7:0]<=countIn;
end

end//EOA

always@(mode) begin	//Assuming mode will have a range of {0,1,2}

if (mode==0) begin
	nextState<=1;	//mode0
end

else if (mode==1) begin
	nextState<=2;	//mode1
end

else  begin
	nextState<=3;	//mode2
end

end//EOA

always@(currentState) begin

if (currentState==0) nextState<=0; //idle and no changes yet

else if (currentState==1) begin    //mode 0
	if (counting==0) begin
		out=0;
	end
	
	else begin
		
		if (gate==1 && activeCount!=0)begin
			out<=0;
			activeCount<=activeCount-1;
		end


		if (activeCount==0)begin
		out<=1;
		counting=0;
		end

	end 

nextState<=1;

end

else if (currentState==2) begin		//mode 1

	if (counting==0) begin
		out<=1;
	end

	else begin
		if (activeCount!=0) begin
			out<=0;
			activeCount<=activeCount-1;
		end
		
		if (activeCount==0) begin
			out<=1;
			counting=0;
		end
	end

nextState<=2;

end

else if (currentState==3) begin

	if (counting==0) begin
		out<=1'b1;
	end

	else begin

		if (activeCount!=1) begin
			out<=1;
			activeCount<=activeCount-1;
		end 
		if (activeCount==1) begin
			out<=0;
			activeCount<=currentCount;
nextState<=3;

end

end //EOA
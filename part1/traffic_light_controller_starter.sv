// traffic light controller
// CSE140L 3-street, 12-state version
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// 4 after traffic, 9 max cycles for green when other traffic present
// starter (shell) -- you need to complete the always_comb logic
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller1(
  input         clk, reset, 
                ew_str_sensor, ew_left_sensor, ns_sensor,  // traffic sensors, east-west straight, east-west left, north-south 
  output colors ew_str_light, ew_left_light, ns_light);    // traffic lights, east-west straight, east-west left, north-south

// LRR = red-red following YRR state; RRL = red-red following RRY state;
// ZRR = 2nd cycle yellow, follows YRR state, etc. 
/*
In the string XYZ, 
X represents the state of the EW straight light, 
Y represents the state of the EW left light, and 
Z represents the state of the NS light. 
So the condition where EW straight is Red, EW left is Green and NS is Red, is represented by the state RGR.
*/
  typedef enum {GRR, YRR, ZRR, LRR, RGR, RYR, RZR, RLR, RRG, RRY, RRZ, RRL} tlc_states;  
  tlc_states    present_state, next_state;
  integer ctr4, next_ctr4,       //  4 sec timeout when my traffic goes away
          ctr9, next_ctr9;     // 9 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
    if(reset) begin
	    present_state <= RRL;
      ctr4          <= 0;
      ctr9         <= 0;
    end  
	else begin
	    present_state <= next_state;
      ctr4          <= next_ctr4;
      ctr9         <= next_ctr9;
    end  

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
    next_state = RRL;            // default to reset state
    next_ctr4  = 0; 	         // default to clearing counters
    next_ctr9 = 0;
    case(present_state)
/* ************* Fill in the case statements ************** */
      GRR: begin 
        // what is next_state value, what are the conditions to update it?
        // what is next_ctr4 value, what are the conditions to update it ? Think of vacant countdown
        // what is next_ctr9 value, what are the conditions to update it ? Think of occupied countdown
		  if(ctr9 == 8) begin
		     next_state = YRR;
		  end else if (ctr4 == 3 ) begin
		     next_state = YRR;
		  end	else begin
			  next_state = GRR;
			 if ((~ew_str_sensor) || ctr4)			                     
				next_ctr4  = ctr4+1;
          if (ew_left_sensor || ns_sensor || ctr9)
				next_ctr9 = ctr9+1;
			end
		end  
      
      //Similar to GRR, think of thr logic to be added in other states 
      //The other states are YRR, ZRR, LRR, RGR, RYR, RZR, RLR, RRG, RRY, RRZ, RRL

      YRR: begin
		     next_state = ZRR;
      end

      ZRR: begin
		     next_state = LRR;
      end
        
      LRR: begin
		if(ew_left_sensor) next_state = RGR; 		
		else if(ns_sensor) next_state = RRG;
		else if(ew_str_sensor) next_state = GRR;
		else next_state = LRR;
      end
        
      RGR: begin
		if (ctr9 == 8) begin
		     next_state = RYR;
		  end else if(ctr4 == 3)  begin
		     next_state = RYR;
		  end	else begin
			 next_state = RGR;
			 if ((~ew_left_sensor) || ctr4)			                     
				next_ctr4  = ctr4+1;
          if (ew_str_sensor || ns_sensor || ctr9)
				next_ctr9 = ctr9+1;
		  end
      
      end
        
      RYR: begin
		     next_state = RZR;
      end
      RZR: begin
		     next_state = RLR;
      end
        
      RLR: begin
		if(ns_sensor) next_state = RRG; 		
		else if(ew_str_sensor) next_state = GRR;
		else if(ew_left_sensor) next_state = RGR;
		else next_state = RLR;	
      
      end
        
      RRG: begin
		
		  if(ctr9 == 8) begin
		     next_state = RRY;
		  end else if (ctr4 == 3 ) begin
		     next_state = RRY;
		  end	else begin					
			 next_state = RRG;
			 if ((~ns_sensor) || ctr4)			                     
				next_ctr4  = ctr4+1;
          if (ew_left_sensor || ew_str_sensor || ctr9)
				next_ctr9 = ctr9+1;
		  end
      
      end
        
      RRY: begin

		     next_state = RRZ;
      
      end
        
      RRZ: begin
		     next_state = RRL;
      
      end
        
      RRL: begin
		if(ew_str_sensor) next_state = GRR;
		else if(ew_left_sensor) next_state = RGR;
		else if(ns_sensor) next_state = RRG; 
		else next_state = RRL;      
      end
      
     
    endcase
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
  always_comb begin
      ew_str_light  = red;                // cover all red plus undefined cases
	  ew_left_light = red;
	  ns_light      = red;
    case(present_state)      // Moore machine
        GRR:     ew_str_light  = green;
	    YRR,ZRR: ew_str_light  = yellow;  // my dual yellow states -- brute force way to make yellow last 2 cycles
	    RGR:     ew_left_light = green;
	    RYR,RZR: ew_left_light = yellow;
	    RRG:     ns_light      = green;
	    RRY,RRZ: ns_light      = yellow;
    endcase
  end

endmodule

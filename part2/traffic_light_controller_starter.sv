// traffic light controller solution stretch
// CSE140L 3-street, 20-state version, ew str/left decouple
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// 4 after traffic, 9 max cycles for green when other traffic present
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller2(
  input 	clk, reset, 
  			e_str_sensor, w_str_sensor, 	// east-west str sensor,
			e_left_sensor, w_left_sensor, 	// east-west left sensor,
			ns_sensor,             			// traffic sensors, north-south 
  
  output colors e_str_light, w_str_light, 	//east-west str, 
  				e_left_light, w_left_light, //east-west left,
				ns_light					// traffic lights,  north-south
				);     

  logic s, sb, e, eb, w, wb, l, lb, n, nb;	 // shorthand for traffic combinations:

   assign s  = e_str_sensor || w_str_sensor;					 	// str E or W
   assign sb = e_left_sensor || w_left_sensor || ns_sensor;			     // 3 directions which conflict with s
// fill in the remaining definitions e, eb, w, wb, l, lb, n, nb;
   assign e  = e_str_sensor || e_left_sensor;					// E str or L
	assign eb = w_str_sensor || w_left_sensor	|| ns_sensor;// conflicts with e
	assign w  = w_str_sensor || w_left_sensor;
	assign wb = e_str_sensor || e_left_sensor || ns_sensor;
	assign l  = e_left_sensor|| w_left_sensor;
	assign lb = w_str_sensor || e_str_sensor  || ns_sensor;
	assign n  = ns_sensor;
	assign nb = w_str_sensor || e_str_sensor  || e_left_sensor || w_left_sensor;


// 20 suggested states, 4 per direction   Y, Z = easy way to get 2-second yellows
// LRRRR = red-red following ZRRRR; ZRRRR = second yellow following YRRRR; 
// RRRRL = red-red following RRRRZ;
  typedef enum {GRRRR, YRRRR, ZRRRR, LRRRR, 	           // ES+WS
  	            RGRRR, RYRRR, RZRRR, RLRRR, 			   // EL+ES
	            RRGRR, RRYRR, RRZRR, RRLRR,				   // WL+WS
	            RRRGR, RRRYR, RRRZR, RRRLR, 			   // WL+EL
	            RRRRG, RRRRY, RRRRZ, RRRRL} tlc_states;    // NS
	tlc_states    present_state, next_state;
	integer ctr4, next_ctr4,       //  4 sec timeout when my traffic goes away
			ctr9, next_ctr9;     // 9 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
	if(reset) begin
	  present_state <= RRRRL;
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
	next_state = RRRRL;                            // default to reset state
	next_ctr4  = 0; 							   // default: reset counters
	next_ctr9 = 0;
	case(present_state)
/* ************* Fill in the case statements ************** */
	  GRRRR: begin                           // ES+WS green 
	  	if(ctr9 == 8)  					   // timeout if others want a turn
 		  next_state = YRRRR;
	  	else if (ctr4 == 3 && (~s))				   // timeout if my traffic goes away
	  	  next_state = YRRRR;
	  	else begin								   // otherwise stay green
	  	  next_state = GRRRR;
	     if (sb || ctr4)			                       // vacant countdown
		    next_ctr4  = ctr4+1;
        if (sb || ctr9)
			 next_ctr9 = ctr9+1;					   // occupied countdown
	    end
	  end
	  YRRRR: next_state = ZRRRR;
	  ZRRRR: next_state = LRRRR;
// fill in
	  LRRRR: begin         // **fill in the blanks in the if ... else if ... chain
	    if (e)
		  next_state = RGRRR;	                         // ES+EL green	     
		else if (w)
		  next_state = RRGRR;							 // WS+WL green
		else if (l)
		  next_state = RRRGR;							 // WL+EL green
		else if (n)
		  next_state = RRRRG;							 // NS green
      else if (s)
		  next_state = GRRRR;
		else
		  next_state = LRRRR;	   
      end
       
	  RGRRR: begin 		                                 // EL+ES green
      if(ctr9 == 8)  					   
 		  next_state = RYRRR;
	  	else if (ctr4 == 3 && (~e))				 
	  	  next_state = RYRRR;
	  	else begin								  
	  	  next_state = RGRRR;
	     if (eb || ctr4)			                     
		    next_ctr4  = ctr4+1;
        if (eb || ctr9)
			 next_ctr9 = ctr9+1;					  
	    end
	  end
	  RYRRR: next_state = RZRRR;
	  RZRRR: next_state = RLRRR;
	  RLRRR: begin
	   if (w)
		  next_state = RRGRR;	                         	     
		else if (l)
		  next_state = RRRGR;							
		else if (n)
		  next_state = RRRRG;							 
		else if (s)
		  next_state = GRRRR;							
      else if (e)
		  next_state = RGRRR;
		else
		  next_state = RLRRR;	   
      end
	  RRGRR: begin 
	   if(ctr9 == 8)  					   
 		  next_state = RRYRR;
	  	else if (ctr4 == 3 && (~w))				 
	  	  next_state = RRYRR;
	  	else begin								  
	  	  next_state = RRGRR;
	     if (wb || ctr4)			                     
		    next_ctr4  = ctr4+1;
        if (wb || ctr9)
			 next_ctr9 = ctr9+1;					  
	    end
	  end
      // ** fill in the guts to complete 5 sets of R Y Z H progressions **
	  RRYRR: next_state = RRZRR;
	  RRZRR: next_state = RRLRR;
	  RRLRR: begin
	   if (l)
		  next_state = RRRGR;	                         	     
		else if (n)
		  next_state = RRRRG;							
		else if (s)
		  next_state = GRRRR;							 
		else if (e)
		  next_state = RGRRR;							
      else if (w)
		  next_state = RRGRR;
		else
		  next_state = RRLRR;	   
      end
	  RRRGR: begin 
	   if(ctr9 == 8)  					   
 		  next_state = RRRYR;
	  	else if (ctr4 == 3 && (~l))				 
	  	  next_state = RRRYR;
	  	else begin								  
	  	  next_state = RRRGR;
	     if (lb || ctr4)			                     
		    next_ctr4  = ctr4+1;
        if (lb || ctr9)
			 next_ctr9 = ctr9+1;					  
	    end
	  end
	  // WL+EL
	  RRRYR: next_state = RRRZR;
	  RRRZR: next_state = RRRLR;
	  RRRLR: begin
	   if (n)
		  next_state = RRRRG;	                         	     
		else if (s)
		  next_state = GRRRR;							
		else if (e)
		  next_state = RGRRR;							 
		else if (w)
		  next_state = RRGRR;							
      else if (l)
		  next_state = RRRGR;
		else
		  next_state = RRRLR;	   
      end
	  RRRRG: begin 
	   if(ctr9 == 8)  					   
 		  next_state = RRRRY;
	  	else if (ctr4 == 3 && (~n))				 
	  	  next_state = RRRRY;
	  	else begin								  
	  	  next_state = RRRRG;
	     if (nb || ctr4)			                     
		    next_ctr4  = ctr4+1;
        if (nb || ctr9)
			 next_ctr9 = ctr9+1;					  
	    end
	  end
	  RRRRY: next_state = RRRRZ;
	  RRRRZ: next_state = RRRRL;
	  RRRRL: begin
	   if (s)
		  next_state = GRRRR;	                         	     
		else if (e)
		  next_state = RGRRR;							
		else if (w)
		  next_state = RRGRR;							 
		else if (l)
		  next_state = RRRGR;							
      else if (n)
		  next_state = RRRRG;
		else
		  next_state = RRRRL;	   
      end
    endcase
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
	always_comb begin
	  e_str_light  = red;                // cover all red plus undefined cases
	  w_str_light  = red;				 // no need to list them below this block
	  e_left_light = red;
	  w_left_light = red;
	  ns_light     = red;
	  case(present_state)      // Moore machine
		GRRRR:   begin 
			e_str_light = green;
			w_str_light = green;
		end
		// ** fill in the guts for all 5 directions -- just the greens and yellows **
		YRRRR:   begin 
			e_str_light = yellow;
			w_str_light = yellow;
		end 
		ZRRRR:   begin 
			e_str_light = yellow;
			w_str_light = yellow;
		end
		
		// EL+ES	
		RGRRR:   begin 
			e_str_light = green;
			e_left_light = green;
		end 
		RYRRR:   begin 
			e_str_light = yellow;
			e_left_light = yellow;
		end 
		RZRRR:   begin 
			e_str_light = yellow;
			e_left_light = yellow;
		end 
		
		// WS+WL green
		RRGRR:   begin 
			w_left_light = green;
			w_str_light = green;
		end 
		RRYRR:   begin 
			w_left_light = yellow;
			w_str_light = yellow;
		end 
		RRZRR:   begin 
			w_left_light = yellow;
			w_str_light = yellow;
		end
	
// WL+EL green	
		RRRGR:   begin 
			w_left_light = green;
			e_left_light = green;
		end 
		RRRYR:   begin 
			w_left_light = yellow;
			e_left_light = yellow;
		end 	
		RRRZR:   begin 
			w_left_light = yellow;
			e_left_light = yellow;
		end

		//NS green
		RRRRG:   begin 
			ns_light = green;
		end 	
		RRRRY:   begin 
			ns_light = yellow;
		end 	
		RRRRZ:   begin 
			ns_light = yellow;
		end 	
		
      endcase
	end
endmodule
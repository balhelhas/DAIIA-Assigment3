/***
* Name: NQuen
* Author: Guilherme, Catalin

***/

model NQueen

/* Insert your model definition here */

global {
	
	int n_queens <- 9;
	int queen_number <- 0;
	bool all_sorted <- false;
	bool start <- true;
	int number_of_cycle <- 0;
	
	init {
		create queen number: n_queens; 
	}
}

species queen skills: [fipa] {
	
	int number;
	cell my_cell;
	bool ask <- false;
	bool force <- false;
	int rejection_cycle <- 0;
	
	init {
		number <- queen_number;
		queen_number <- queen_number + 1;
		
		my_cell <- cell(number);	
		location <- my_cell.location;
	}
	
	aspect default {
    	draw sphere(2) color: #blue;
    }
    
    //Start moving queens arround
    reflex start_moving when: number = 0 and start {
		ask <- true;
		start <- false;
	}
    
    //If queen needs to ask for the next queen to move
    reflex ask_to_move when: ask {
		int ask_queen;
		if(number = n_queens - 1) {
			ask_queen <- 0;
		} else {
			ask_queen <- number + 1;
		}
		if(number = 0) {
			number_of_cycle <- number_of_cycle +1;
		}
		do start_conversation(
			to: [queen[ask_queen]],
			protocol: 'fipa-propose',
			performative: 'propose',
			contents: [self, ""]
		);
		ask <- false;
	}
    
    //When a queen receives a proposal to move
    reflex asked_to_move when: !empty(proposes) {
		message proposal <- proposes at 0;
		queen asking_queen <- proposal.contents at 0;
		string info <- proposal.contents at 1;
		
		write name + " at:" + my_cell +" Asked to move by: " + asking_queen;
		
		if(my_cell.has_intercepted_queen()) {
			cell current <- my_cell;
			
			loop position over: my_cell.verticals {
				my_cell <- position;
				if(!my_cell.has_intercepted_queen()){
					location <- my_cell.location;
					break;
				}
			}
			
			if(current.location = location){
				my_cell <- current;
				if(info = "CAN YOU FORCE MOVE") {
					write "I was forced";
					do reject_proposal with: (message: proposal, contents: [self, "I CANT BE FORCED"]);
				} else {
					write "No";
					do reject_proposal with: (message: proposal, contents: [self, ""]);
				}
			}
			
			if(info != "CAN YOU MOVE" or info = "CAN YOU FORCE MOVE"){
				ask <- true;	
			}
		}
	}
	
	//When a queen rejects to move
	reflex got_rejection when: !empty(reject_proposals) {
		message rejected_message <- reject_proposals at 0;
		queen fail_queen <- rejected_message.contents at 0;
		string info <- rejected_message.contents at 1;
		
		write name + " My comand to move reject by: " + fail_queen;
		
		//If one cycle as passed and there are still rejection do forced moves
		if(number_of_cycle > 1) {
			map<cell,list<queen>> how_many <- fail_queen.my_cell.intercepted_queens();
			
			loop queens over: how_many {
				if(length(queens) = 1) {
					cell move_to <- how_many index_of queens;
					fail_queen.my_cell <- move_to;
					fail_queen.location <- move_to.location;
					
					ask fail_queen {
						do force_move(queens[0]);
					}
					break;
				}
			}	
		} else {
			//Ask the queen to move again if it's the first cycle
			do start_conversation(
				to: [fail_queen],
				protocol: 'fipa-propose',
				performative: 'propose',
				contents: [self, "CAN YOU MOVE"]
			);		
		}
	}
	
	//If there are no more proposes but there is still a interception make a sneaky move
	reflex sneaky_move when: empty(proposes) and number_of_cycle > 1 {
		if(my_cell.has_intercepted_queen()) {
			cell current <- my_cell;
			
			loop position over: my_cell.verticals {
				my_cell <- position;
				if(!my_cell.has_intercepted_queen()){
					location <- my_cell.location;
					break;
				}
			}
			
			if(current.location = location){
				my_cell <- current;
			}
		}
	}
	
	//If there are still interceptions start new force
	reflex still_has_interceptions when: empty(proposes) and my_cell.has_intercepted_queen() {
		map<cell,list<queen>> how_many <- my_cell.intercepted_queens();
			
		loop queens over: how_many {
			if(length(queens) = 1) {
				cell move_to <- how_many index_of queens;
				my_cell <- move_to;
				location <- move_to.location;
				
				do force_move(queens[0]);	
				break;
			}
		}
	}
	
	//Do a force move
	action force_move (queen move_it) {
		do start_conversation(
			to: [move_it],
			protocol: 'fipa-propose',
			performative: 'propose',
			contents: [self, "CAN YOU FORCE MOVE"]
		);
	}
}

grid cell width: n_queens height: n_queens neighbors: 4 {
	
	int column <- grid_x;
	int row <- grid_y; 
	list<cell> horizontals;
	list<cell> verticals;
	list<cell> diagonals;
	
	init {
		do set_color;
		do get_horizontal_row;
		do get_vertical_row;
		do get_diagonal_rows;
	}
	
	//Check if the cell has intercepted queens
	bool has_intercepted_queen {
		bool has_queen <- false;
		
		loop q over: queen {
			loop horizontal over: horizontals{
				if(q.my_cell = horizontal){
					has_queen <- true;
					break;
				}
			}
			loop vertical over: verticals {
				if(q.my_cell = vertical){
					has_queen <- true;
					break;
				}
			}
			loop diagonal over: diagonals {
				if(q.my_cell = diagonal){
					has_queen <- true;
					break;
				}
			}
		}
		
		return has_queen; 
	}
	
	//Get a map of the intercepted queens for each move of a queen 
	map<cell,list<queen>> intercepted_queens {
		map<cell,list<queen>> moves;
		list<queen> queens_intercepted;
		
		loop c over:verticals {
			loop q over: queen {
				if(q.my_cell != self) {
					loop horizontal over: c.horizontals{
						if(q.my_cell = horizontal){
							add q to: queens_intercepted;
						}
					}
					loop vertical over: c.verticals {
						if(q.my_cell = vertical){
							add q to: queens_intercepted;
						}
					}
					loop diagonal over: c.diagonals {
						if(q.my_cell = diagonal){
							add q to: queens_intercepted;
						}
					}	
				}
			}
			add queens_intercepted at: c to: moves;
			queens_intercepted <- [];
		}
		
		return moves;
	}
	
	//Create a chess board coloring
	action set_color {
		if row mod 2 = 0 {
			color <- column mod 2 = 0 ?  #black : #white;
		} else {
			color <- column mod 2 = 0 ?  #white : #black;
		}
	}
	
	//Get the horizontal row of a cell
	action get_horizontal_row {		
		loop x from: 0 to: n_queens -1 {
			if(cell[x, row] != self) {
				add cell[x, row] to: horizontals;	
			}
		}
	}
	
	//Get the vertical row of a cell
	action get_vertical_row {
		loop y from: 0 to: n_queens -1 {
			if(cell[column, y] != self) {
				add cell[column, y] to: verticals;	
			} 
		}
	}
	
	//Get the diagonal rows of a cell
	action get_diagonal_rows  {
		loop c from: 0 to: n_queens - 1 {
			cell down_left <- cell[column + c, row + c];
			cell down_right <- cell[column + c, row - c];
			cell up_left <- cell[column - c, row + c];
			cell up_right <- cell[column - c, row - c];
			
			if (down_left != nil and down_left != self) {
				add down_left to: diagonals; 
			}
			if (down_right != nil and down_right != self) {
				add down_right to: diagonals; 
			}
			if (up_left != nil and up_left != self) {
				add up_left to: diagonals; 
			}
			if (up_right != nil and up_right != self) {
				add up_right to: diagonals; 
			}
		}
	}
}

experiment ChessBoard type: gui {
	/** Insert here the definition of the input and output of the model */
	// input
	parameter "Number of queens: " var: n_queens min: 4  category: "Quens";
	
	// output
	output {
		// opengl adds the 3d part
		display main_display type:opengl{
			grid cell lines: #black;
			species queen aspect: default;
		}
	}
}
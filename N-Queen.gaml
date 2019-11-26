/***
* Name: NQuen
* Author: greenl3af
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NQueen

/* Insert your model definition here */

global {
	
	int n_queens <- 4;
	int queen_number <- 0;
	bool all_sorted <- false;
	bool start <- true;
	
	init {
		create queen number: n_queens; 
	}
}

species queen skills: [fipa] {
	
	int number;
	int cycle;
	cell my_cell;
	bool ask <- false;
	
	init {
		number <- queen_number;
		queen_number <- queen_number + 1;
		
		my_cell <- cell(number);	
		location <- my_cell.location;
	}
	
	aspect default {
    	draw sphere(2) color: #blue;
    }
    
    reflex start_moving when: number = 0 and start {
		ask <- true;
		start <- false;
	}
    
    reflex ask_to_move when: ask {
		int ask_queen;
		if(number = n_queens - 1) {
			ask_queen <- 0;
		} else {
			ask_queen <- number + 1;
		}
		do start_conversation(
			to: [queen[ask_queen]],
			protocol: 'fipa-propose',
			performative: 'propose',
			contents: [my_cell.get_available_possitions(), self, ""]
		);
		ask <- false;
	}
    
    reflex asked_to_move when: !empty(proposes) {
		message proposal <- proposes at 0;
		queen asking_queen <- proposal.contents at 1;
		list<cell> proposed_positions <- proposal.contents at 0;
		string info <- proposal.contents at 2;
		
		write name + " at:" + my_cell +" Asked to move by: " + asking_queen;
		
		if(my_cell.intercepted_queen()) {
			cell current <- my_cell;
			
			loop position over: proposed_positions {
				if(position.grid_x = my_cell.grid_x) {
					my_cell <- position;
					if(!my_cell.intercepted_queen()){
						location <- my_cell.location;
						break;
					}
				}
			}
			
			if(current.location = location){
				my_cell <- current;
				do reject_proposal with: (message: proposal, contents: [proposed_positions, self, ""]);
			}
			
			if(info != "CAN YOU MOVE"){
				ask <- true;	
			}
		}
	}
	
	reflex got_rejection when: !empty(reject_proposals) {
		message rejected_message <- reject_proposals at 0;
		list<cell> proposed_positions <- rejected_message.contents at 0;
		queen fail_queen <- rejected_message.contents at 1;
		string info <- rejected_message.contents at 2;
		write name + " My comand to move reject by: " + fail_queen;
		
		do start_conversation(
			to: [fail_queen],
			protocol: 'fipa-propose',
			performative: 'propose',
			contents: [proposed_positions, self, "CAN YOU MOVE"]
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
		do get_diagonal_row;
	}
	
	list get_available_possitions {
		list<cell> positions;	
		
		loop y from: 0 to: n_queens - 1 {
			loop x from: 0 to: n_queens -1 {
				if(x != column and y != row) {
					add cell[x, y] to: positions; 
				}
			}
		}
		
		loop diagonal over: diagonals {
			remove diagonal from: positions;
		}
		
		return positions;
	}
	
	bool intercepted_queen {
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
	
	action set_color {
		if row mod 2 = 0 {
			color <- column mod 2 = 0 ?  #black : #white;
		} else {
			color <- column mod 2 = 0 ?  #white : #black;
		}
	}
	
	action get_horizontal_row {		
		loop x from: 0 to: n_queens -1 {
			if(cell[x, row] != self) {
				add cell[x, row] to: horizontals;	
			}
		}
	}
	
	action get_vertical_row {
		loop y from: 0 to: n_queens -1 {
			if(cell[column, y] != self) {
				add cell[column, y] to: verticals;	
			} 
		}
	}
	
	action get_diagonal_row  {
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
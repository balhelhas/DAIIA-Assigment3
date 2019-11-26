/***
* Name: NQuen
* Author: greenl3af
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NQuen

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
	
	int my_number;
	cell my_cell;
	bool ask <- false; 
	list<cell> possible_positions;
	
	init {
		my_number <- queen_number;
		queen_number <- queen_number + 1;
	
		my_cell <- cell(my_number);	
		location <- my_cell.location;
	}
	
	aspect default {
    	draw sphere(2) color: #blue;
    }
    
	reflex start_moving when: my_number = 0 and start {
		
		possible_positions <- get_available_possitions();
		
		ask <- true;
		
		start <- false;
	}
	
	reflex ask_to_move when: ask {
//		int ask_queen;
//		if(my_number = n_queens - 1) {
//			ask_queen <- 0;
//		} else {
//			ask_queen <- my_number + 1;
//		}
		loop q from: 0 to: n_queens-1 {
			if(q != my_number) {
				do start_conversation(
					to: [queen[q]],
					protocol: 'fipa-propose',
					performative: 'propose',
					contents: [possible_positions]
				);		
			}
		}
		
		ask <- false;
	}
	
	reflex asked_to_move when: !all_sorted and !empty(proposes) {
		message proposal <- proposes at 0;
		list<cell> my_possible_positions <- proposal.contents at 0;
		
		write name + " cell: " + my_cell;
		
		if(is_queen_somewhere()) {
			cell current <- my_cell;
		
			loop position over: my_possible_positions {
				if(position.grid_x = my_cell.grid_x) {
					my_cell <- position;
					if(!is_queen_somewhere()){
						location <- my_cell.location;
						break;
					}
				}
			}
			
			write my_cell;
			
			if(current.location = location){
				my_cell <- current;
			}
			
			possible_positions <- get_available_possitions();
			
			ask <- true;
		}
	}
	
	
	bool is_queen_somewhere {
		write my_cell;
		bool has_queen <- false;
		
		list<cell> horizontal_row <- get_horizontal_row();
		list<cell> vertical_row <- get_vertical_row();
		list<cell> diagonal_row <- get_diagonal_row();
		
		loop q over: queen {
			loop horizontal over: horizontal_row {
				if(q.my_cell = horizontal){
					has_queen <- true;
					break;
				}
			}
			loop vertical over: vertical_row {
				if(q.my_cell = vertical){
					has_queen <- true;
					break;
				}
			}
			loop diagonal over: diagonal_row {
				if(q.my_cell = diagonal){
					has_queen <- true;
					break;
				}
			}
		}
		
		
		return has_queen; 
	}
	
	list get_available_possitions {
		int my_x <- my_cell.grid_x;
		int my_y <- my_cell.grid_y;
	
		list<cell> positions;	
		list<cell> diagonals <- get_diagonal_row();
		
		
		loop y from: 0 to: n_queens - 1 {
			loop x from: 0 to: n_queens -1 {
				if(x != my_x and y != my_y) {
					add cell[x, y] to: positions; 
				}
			}
		}
		
		loop diagonal over: diagonals {
			remove diagonal from: positions;
		}
		
		return positions;
	}
	
	list get_horizontal_row {
		list<cell> horizontals;
		int my_y <- my_cell.grid_y;
		
		loop x from: 0 to: n_queens -1 {
			if(cell[x, my_y] != my_cell) {
				add cell[x, my_y] to: horizontals;	
			}
		}
		
		return horizontals;
	}
	
	list get_vertical_row {
		list<cell> verticals;
		int my_x <- my_cell.grid_x;
		
		loop y from: 0 to: n_queens -1 {
			if(cell[my_x, y] != my_cell) {
				add cell[my_x, y] to: verticals;	
			} 
		}
		
		return verticals;
	}
	
	list get_diagonal_row {
		list<cell> diagonals;
		int my_x <- my_cell.grid_x;
		int my_y <- my_cell.grid_y;
		
		loop c from: 0 to: n_queens - 1 {
			cell down_left <- cell[my_x + c, my_y + c];
			cell down_right <- cell[my_x + c, my_y - c];
			cell up_left <- cell[my_x - c, my_y + c];
			cell up_right <- cell[my_x - c, my_y - c];
			
			if(down_left != nil and down_left != my_cell) {
				add down_left to: diagonals; 
			}
			if(down_right != nil and down_right != my_cell) {
				add down_right to: diagonals; 
			}
			if(up_left != nil and up_left != my_cell) {
				add up_left to: diagonals; 
			}
			if(up_right != nil and up_right != my_cell) {
				add up_right to: diagonals; 
			}
		}
		
		return diagonals;
	}
	
}

grid cell width: n_queens height: n_queens neighbors: 4 {
	
	int column <- grid_x;
	int row <- grid_y; 
	
	init {
		do set_color;
	}
	
	action set_color {
		if row mod 2 = 0 {
			color <- column mod 2 = 0 ?  #black : #white;
		} else {
			color <- column mod 2 = 0 ?  #white : #black;
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
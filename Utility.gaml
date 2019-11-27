/***
* Name: Utility
* Author: Guilherme, Catalin
***/

model Utility

global {
	
	int number_of_guests <- rnd(10) + 10;
	rgb wandering_color <- #gray;
	float guests_speed <-  0.5;
	
	int number_of_stages <- 3;
	int stage_size_min <- 4;
	int stage_size_max <- 6;
	int stage_util_min <- 1;
	int stage_util_max <- 100;
	int show_duration_min <- 200;
	int show_duration_max <- 500;
	
	list<rgb> stage_colors <- [#blue, #yellow, #green, #red, #purple, #pink, #orange, #black, #brown, #cyan];
	list<string> music_genres <- ["country", "electro", "blues", "rock", "hip-hop", "pop", "jazz"];
	
	init {
		create Guest number: number_of_guests;
		create Stage number: number_of_stages;
	}
}

/* Insert your model definition here */
species Guest skills: [moving, fipa]{
	
	rgb my_color <- wandering_color;
	float actual_utility <- 0.0;
	
	list<float> stage_utils <- [];
	
	float my_util_lights <- rnd(stage_util_min,stage_util_max) * 0.01;
	float my_util_music <- rnd(stage_util_min,stage_util_max) * 0.01;
	float my_util_show <- rnd(stage_util_min,stage_util_max) * 0.01;
	float my_util_decor <- rnd(stage_util_min,stage_util_max) * 0.01;
	float my_util_artists <- rnd(stage_util_min,stage_util_max) * 0.01;
	
	string my_genre <- music_genres[rnd(length(music_genres) - 1)];
	float bias_genre <- rnd(1.0,10.0); 
	
	int my_crowd_size <- rnd(1, number_of_guests);
	float bias_crowd_size <- rnd(1.0,10.0);
	
	Stage picked_stage <- nil;
	
	aspect default {
		draw sphere(2) at: location color: my_color;
	}
	
	reflex wander when: picked_stage = nil {
		do wander;
	}
	
	reflex pick_stage when: !empty(cfps){
		message request <- cfps at 0;
		loop request over: cfps {
			if (request.contents[0] = 'Start') {
				//Calculate utility for the stage
				float utility <- float(request.contents[2]) * my_util_lights + 
								 float(request.contents[3]) * my_util_music +
								 float(request.contents[4]) * my_util_show +
								 float(request.contents[5]) * my_util_decor +
								 float(request.contents[6]) * my_util_artists;
				
				//If the stage genre if the same as the prefered genre of guest multiply by bias
				if(request.contents[1] = my_genre) {
					utility <- utility * bias_genre;
				}
				
				//If crowd size is smaller than the prefered crowd multiply by bias
				if(length(Stage(request.sender).crowd) <= my_crowd_size) {
					utility <- utility * bias_crowd_size;
				}
				
				// check if it's a better utility and change stage
				if (utility > actual_utility){
					picked_stage <- request.sender;
					my_color <- picked_stage.color;
					write "Guest " + name + " has max utilities (" + round(utility) + ";" + round(actual_utility) +") for stage " 
						+ picked_stage.name + "(" + picked_stage.color + ")";
					actual_utility <- utility;
					add self to: picked_stage.crowd;
				}
			} else if (request.contents[0] = 'Stop'){
				actual_utility <- 0.0;
				my_color <- wandering_color;
				picked_stage <- nil;
			}	
		}
	}
		
	reflex go_to_stage when: picked_stage != nil {
		if(location distance_to(picked_stage) > (picked_stage.size + 5)) {
			do goto target:{picked_stage.location.x + 5, picked_stage.location.y + 5} speed: guests_speed;	
		}
	}
	
	reflex at_stage when: picked_stage != nil 
					and location distance_to(picked_stage.location) <= picked_stage.size + 5 {
		do wander speed: guests_speed bounds: circle(0.5);
	}
	
}

species Stage skills: [fipa]{
	int size <- rnd(stage_size_min, stage_size_max);
	rgb color;
	string genre;
	
	// For how long the show will run
	float start_time;
	int show_duration <- rnd(show_duration_min, show_duration_max);
	
	// Stage utilities to calculate guest utility when deciding to which stage to go
	int util_lights;
	int util_music;
	int	util_show;
	int util_decor;
	int util_artists;
	
	// Record of the crowd of the stage
	list<Guest> crowd <-[];
	
	init {
		do set_utilities;
		write name+"(" + self.color + ") will start a show of "+ genre;
	}
	
	aspect default {
		draw cylinder(size, 0.1) color: self.color at: location;
	}
	
	//When the show is over, remove stage from the stages list and remove stage util from the guests and reset them 
	reflex shutdown_show when: time >= start_time + show_duration {
		write "\n------------" + name + "'s(" + self.color + ") " + genre + " show has finished ----------------\n";	
		// anounce Guests about show end
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
		// announce Stages about show end
		do start_conversation (to: list(Stage) - self, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
		
		// change location when concert finished
		self.location <- {rnd(100),rnd(100)};
		do set_utilities;
		write "\n------------ " + name + "(" + self.color + ") started a new show of "+ genre + "-------------\n";
	}
	
	// re-announce every guest about the place in case one stage closes
	reflex resend_data when: !empty(cfps){
		message request <- cfps at 0;
		if (request.contents[0] = 'Stop') {
			// announce through FIPA the guests
			do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', 
				contents: ['Start', genre, util_lights, util_music, util_show, util_decor, util_artists, color]);
		}
	}
	
	// recreate utilities and send again message to everyone
	action set_utilities {
		// empty the crowd
		crowd <- [];
		
		color <- stage_colors[rnd(length(stage_colors) - 1)];
		genre <- music_genres[rnd(length(music_genres) - 1)];
	
		// For how long the show will run
		start_time <- time;
		show_duration <- rnd(show_duration_min, show_duration_max);
	
		// Stage utilities to calculate guest utility when deciding to which stage to go
		util_lights <- rnd(stage_util_min,stage_util_max);
		util_music <- rnd(stage_util_min,stage_util_max);
		util_show <- rnd(stage_util_min,stage_util_max);
		util_decor <- rnd(stage_util_min,stage_util_max);
		util_artists <- rnd(stage_util_min,stage_util_max);
		
		// announce through FIPA
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', 
			contents: ['Start', genre, util_lights, util_music, util_show, util_decor, util_artists, color]);
	}
}

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species Guest;
			species Stage;
		}
	}
}
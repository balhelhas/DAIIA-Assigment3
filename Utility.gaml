/***
* Name: Utility
* Author: Guilherme, Catalin
***/

model Utility

global {
	
	int number_of_guests <- rnd(10) + 10;
	rgb wandering_color <- #gray;
	float guests_speed <-  0.5;
	
	int number_of_stages <- 5;
	int stage_size_min <- 4;
	int stage_size_max <- 6;
	int stage_util_min <- 1;
	int stage_util_max <- 100;
	int show_duration_min <- 200;
	int show_duration_max <- 500;
	
	list<rgb> stage_colors <- [#blue,#yellow,#green,#red,#purple];
	list<string> music_genres <- ["country","electronic","blues","rock","hip-hop","pop","jazz"];
	
	list<Stage> stages <- [];
	
	init {
		create Guest number: number_of_guests;
		create Stage number: number_of_stages {
			add self to: stages;
		}
	}
}

/* Insert your model definition here */
species Guest skills: [moving]{
	
	rgb my_color <- wandering_color;
	
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
	
	//Constatly calculating utilities for the stages
	reflex calculate_my_utils {
		if(!empty(stages)) {
			loop s from: 0 to: length(stages)-1 {
				//Get the index stage on list of stages
				Stage stage <- stages[s];
				
				//Calculate utility for the stage
				float utility <- stage.util_lights * my_util_lights +
								 stage.util_music * my_util_music +
								 stage.util_show * my_util_show +
								 stage.util_decor * my_util_decor +
								 stage.util_artists * my_util_artists;
				
				//If the stage genre if the same as the prefered genre of guest multiply by bias
				if(stage.genre = my_genre) {
					utility <- utility * bias_genre;
				}
				
				//If crowd size is smaller than the prefered crowd multiply by bias
				if(length(stage.crowd) <= my_crowd_size) {
					utility <- utility * bias_crowd_size;
				}
				
				if( length(stage_utils) != length(stages)){
					add utility to: stage_utils;
				} else {
					put utility at: s in: self.stage_utils;	
				}
			}
		} else {
			stage_utils <- [];
		}
	}
	
	//Once all utilities are calculate pick the stage with the highest utility
	reflex pick_stage when: !empty(stages) and !empty(stage_utils) 
					  		and length(stages) = length(stage_utils) {	
		
		float high_util <- 0.0;
		int stage;
		
		loop u from: 0 to: length(stage_utils)-1 {
			if(stage_utils[u] >= high_util) {
				high_util <- stage_utils[u];
				stage <- u;
			}
		}
		
		picked_stage <- stages[stage];
		my_color <- picked_stage.color;
		add self to: picked_stage.crowd;
		
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

species Stage {
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
		write name+"'s will start a show of "+ genre;
	}
	
	aspect default {
		draw cylinder(size, 0.1) color: color at: location;
	}
	
	//When the show is over, remove stage from the stages list and remove stage util from the guests and reset them 
	reflex shutdown_show when: time >= start_time + show_duration {
		write name + "'s " + genre + " show has finished";	
		int stage_index <- stages index_of self;
		
		do set_utilities;
		
		write name+"'s will start a new show of "+ genre;
	}
	
	action set_utilities {
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
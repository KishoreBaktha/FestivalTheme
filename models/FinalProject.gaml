/**
* Name: ID2209 Final Project
* Author: Khoa Dinh, Kishore Baktha
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Festival

/* Insert your model definition here */

global
{
	float agent_speed <- 3.0;
	list<string> music_genres <- ["Jazz", "Pop", "Indie", "Rock"];
	list<string> guest_types <- ["Party", "Chill", "Gloomy", "Celebrity"];
	
	int number_of_guests <- 50;
	int number_of_thiefs <- 5;
	int number_of_guards <- 3;
	int number_of_artists <- 3;
	int number_of_janitors <- 3;
	
	int number_of_foodstore <- 1;
	int number_of_drinkstore <- 1;
	
	point information_center_location <- {50, 50};
	
	float hunger_progress <- 0.01;
	float thirst_progress <- 0.01;
	
	float global_happiness -> {Guest sum_of(each.happiness)};
	
	bool enable_social_encounters <- true;
	bool enable_firework <- true;
	
	init {			
		create Guest number:number_of_guests;
		create Thief number: number_of_thiefs;
		create Guard number: number_of_guards;
		create Artist number: number_of_artists;
		create Janitor number: number_of_janitors;
		
		create InformationCenter number: 1;
		create FoodStore number: number_of_foodstore;
		create DrinkStore number: number_of_drinkstore;
		
		create Sun number: 1;
		create Moon number: 1;
		create Firework number: 5;		
	}
	
	// Let the simulation runs for 3 days (1 minute = 1 cycle)
	reflex stop_simulation when: time = 4320 {
		do pause ;
	} 			
}

species Guest skills: [moving] control: simple_bdi
{		
	rgb color <- #green;
	float vision <- 5.0;
	float hunger_level <- rnd(1000)/1000;
	float thirst_level <- rnd(1000)/1000;
	
	list<string> music_preferences <- [
		music_genres at rnd(length(music_genres) - 1),
		music_genres at rnd(length(music_genres) - 1)
	];
	
	string personality <- guest_types at rnd(length(guest_types) - 1);	
	float chance_to_mingle <- rnd(1000)/1000;
	
	float happiness <- 1.0;
	int money <- rnd(100) + 100;
	
	point target_location <- nil;
	point waiting_location <- nil;
	Artist target_artist <- nil;
	
	list<point> foodstore_location <- [];
	list<point> drinkstore_location <- [];
	
	predicate hanging_around <- new_predicate("hanging_around");
	predicate goto_info_center <- new_predicate("goto_info_center");	
	
	predicate being_hungry <- new_predicate("being_hungry");
	predicate get_food <- new_predicate("get_food");
	
	predicate being_thirsty <- new_predicate("being_thirsty");
	predicate get_drink <- new_predicate("get_drink");
	
	predicate nearby_performance <- new_predicate("nearby_performance");
	predicate watch_performance <- new_predicate("watch_performance");
	
	init {
		speed <- agent_speed;
		do add_desire(hanging_around) strength: 1.0;
	}
			
	reflex happiness_process
	{
		if (has_belief(being_hungry) or has_belief(being_thirsty))
		{
			happiness <- max([happiness - 0.01, 0]);
		}
		
		list<Trash> nearbyTrash <- Trash where(each.location distance_to(location) < 3);
		happiness <- max([happiness - 0.001 * length(nearbyTrash), 0]);			
	}	
			
	reflex get_hungry when: hunger_level < 1.0 {
		hunger_level <- hunger_level + hunger_progress;
		if (hunger_level >= 1.0)
		{
			do add_belief(being_hungry);
		}
	}
	
	reflex get_thirsty when: thirst_level < 1.0 {
		thirst_level <- thirst_level + thirst_progress;
		if (thirst_level >= 1.0)
		{
			do add_belief(being_thirsty);
		}
	}
	
	reflex found_artist
	{
		list<Artist> nearbyArtists <- Artist where(each.genre in music_preferences and each.is_performing and each.location distance_to(location) < vision * 2);
		if (!empty(nearbyArtists))
		{
			target_artist <- nearbyArtists[0];
			do add_belief(nearby_performance);
		}
		else
		{
			target_artist <- nil;
			do remove_belief(nearby_performance);
		}			
	}
	
	reflex litter
	{
		if (rnd(777) = 7)
		{
			point guest_location <- location;
			
			create Trash number: 1
			{
				location <- guest_location;
			}
		}
	}		
	
	perceive target:FoodStore in:vision {		
		if (!(location in myself.foodstore_location))
		{
			myself.foodstore_location <- myself.foodstore_location + location;
		}
	}
	
	perceive target:DrinkStore in:vision {
		if (!(location in myself.drinkstore_location))
		{
			myself.drinkstore_location <- myself.drinkstore_location + location;
		}
	}
	
	rule belief: being_hungry remove_intention: hanging_around new_desire: get_food strength: 5.0;		
	rule belief: being_thirsty remove_intention: hanging_around new_desire: get_drink strength: 5.0;
	rule belief: nearby_performance remove_intention: hanging_around new_desire: watch_performance strength: 6.0;
	
	plan plan_hanging_around intention:hanging_around
	{
		do wander amplitude: 3;
	}
	
	plan plan_goto_info_center intention:goto_info_center
	{
		do goto target:information_center_location;
		target_location <- information_center_location;
	}
	
	plan plan_get_food intention:get_food
	{
		if (target_location = nil)
		{			
			if (!empty(foodstore_location))
			{
				target_location <- foodstore_location closest_to(self);
			}	
			
			if (target_location = nil)
			{
				do add_subintention(get_food, goto_info_center, true);
				do current_intention_on_hold();
			}
		}
		
		if (target_location != nil)
		{
			if (waiting_location = nil)
			{
				do goto target:target_location;
			}
			else 
			{
				do goto target: waiting_location;			
				do queue_mingle;
			}		
		}						
	}
	
	
	plan plan_get_drink intention:get_drink
	{
		if (target_location = nil)
		{			
			if (!empty(drinkstore_location))
			{
				target_location <- drinkstore_location closest_to(self);
			}	
			
			if (target_location = nil)
			{
				do add_subintention(get_drink, goto_info_center, true);
				do current_intention_on_hold();
			}
		}
		
		if (target_location != nil)
		{
			if (waiting_location = nil)
			{
				do goto target:target_location;
			}
			else 
			{
				do goto target: waiting_location;
				do queue_mingle;			
			}		
		}	
	}
	
	plan plan_watch_performance intention: watch_performance
	{		
		if (target_artist != nil and target_artist.is_performing)
		{
			if (waiting_location = nil)			
			{
				int  size <- 10;
				waiting_location <- {
					target_artist.location.x - size + rnd (2 * size),
					target_artist.location.y - size + rnd (2 * size)
				};
			}
			
			happiness <- min([happiness + 0.02 * target_artist.skill_level, 1]);
			
			do goto target: waiting_location;
			do performance_mingle;
		}
		else
		{
			waiting_location <- nil;
			do remove_belief(nearby_performance);
			do remove_intention(watch_performance, true);
		}
	}
	
	action performance_mingle
	{
		if (enable_social_encounters)
		{
			list<Guest> nearbyGuests <- Guest where(each.location distance_to(location) < 3 and each.target_artist = target_artist);
			bool should_mingle <- rnd(1000)/1000 < chance_to_mingle;
			if (!empty(nearbyGuests) and should_mingle)
			{
				Guest guest <- nearbyGuests at rnd(length(nearbyGuests) - 1);
				float compatability <- calculate_mingle_compatability(guest);
				happiness <- min([happiness + compatability, 1]);
				
				write name + " meet " + guest + "  at a performance";
			}
		}
		
	}
	
	action queue_mingle
	{		
		if (enable_social_encounters)
		{
			list<Guest> nearbyGuests <- Guest where(each.location distance_to(location) < 3 and each.waiting_location != nil and each.target_location = target_location);
			bool should_mingle <- rnd(1000)/1000 < chance_to_mingle;
			if (!empty(nearbyGuests) and should_mingle)
			{			
				Guest guest <- nearbyGuests at rnd(length(nearbyGuests) - 1);
				float compatability <- calculate_mingle_compatability(guest);
				happiness <- min([happiness + compatability, 1]);
				
				write name + " meet " + guest + "  in a waiting queue";
			}
		}		
	}
	
	action calculate_mingle_compatability(Guest guest)
	{
		if (guest.personality = "Celebrity")
		{
			return 0.8;
		}
		else if (guest.personality = personality) {
			return 0.5;
		}
		else {
			return 0.2;
		}
	}
	
	action consume_drink
	{
		thirst_level <- 0.0;
		happiness <- min([happiness + 0.3, 1]);
		target_location <- nil;
		
		do remove_intention(get_drink, true);
		do remove_belief(being_thirsty);
	}
	
	action consume_food
	{
		hunger_level <- 0.0;
		happiness <- min([happiness + 0.3, 1]);
		target_location <- nil;
						
		do remove_intention(get_food, true);
		do remove_belief(being_hungry);
	}
	
	action get_info_about_store(point foodStore, point drinkStore)
	{
		foodstore_location <- [foodStore];
		drinkstore_location <- [drinkStore];
		target_location <- nil;
		
		do remove_intention(goto_info_center, true);
	}
	
	aspect base {
		draw box(1, 1, 2) color: color;
		draw box(3, 1, 3) color: color at: {location.x, location.y, location.z + 2};
		draw box(1, 1, 1) color: color at: {location.x, location.y, location.z + 5};
	}
}

species Guard skills: [moving]
{
	float vision <- 10.0;
	rgb color <- #black;
	Thief target;
		
	init
	{
		speed <- agent_speed;
	}
	
	reflex wander 
	{
		do wander amplitude: 5;
	}
	
	reflex detect_thief when: target = nil or dead(target)
	{
		list<Thief> nearbyThiefs <- Thief where(each.target != nil and each.location distance_to(location) < vision);
		if (!empty(nearbyThiefs))
		{
			target <- nearbyThiefs[0];
		}
	}
	
	reflex chase_thief when: target != nil and !dead(target)
	{
		do goto target:target.location speed: 6.0;
	}
	
	reflex catch_thief when: target != nil and !dead(target) and location distance_to(target.location) < 2
	{
		write name + " caught " + target;
		ask target 
		{
			do die;
		}
		
		list<Guest> nearbyGuests <- Guest where(each.location distance_to(location) < 10);
		loop guest over: nearbyGuests
		{
			guest.happiness <- min([guest.happiness + 0.3, 1]);
		}
		
		target <- nil;
	}
	
	aspect base {
		draw box(1, 1, 2) color: color;
		draw box(3, 1, 3) color: color at: {location.x, location.y, location.z + 2};
		draw box(1, 1, 1) color: color at: {location.x, location.y, location.z + 5};
	}
}

species Thief skills: [moving]
{
	rgb color <- #red;
	int money <- 0;
	float time_to_steal;
	Guest target;
	
	init
	{
		speed <- agent_speed;
	}
	
	reflex wander 
	{
		do wander amplitude: 5;
	}
	
	reflex find_target when: target = nil
	{
		list<Guest> nearbyGuests <- Guest where(each.location distance_to(location) < 5);
		list<Guest> guestToStealFrom <- nearbyGuests where(each.location distance_to(location) < 2);
		
		if (length(nearbyGuests) > 5 and !empty(guestToStealFrom))
		{
			target <- guestToStealFrom[0];	
			time_to_steal <- time + 1;		
		}
	}
	
	reflex steal when: target != nil and time = time_to_steal
	{
		write name + " stole money from" + target;
		
		ask target
		{
			int stolenAmount <- max([rnd(20), self.money]);
			self.money <- self.money - stolenAmount;
			self.happiness <- max([self.happiness - 0.8, 0]);
			
			myself.money <- myself.money + stolenAmount;								
		}
		
		target <- nil;
	}
	
	aspect base {
		draw box(1, 1, 2) color: color;
		draw box(3, 1, 3) color: color at: {location.x, location.y, location.z + 2};
		draw box(1, 1, 1) color: color at: {location.x, location.y, location.z + 5};
	}
}

species Artist skills: [moving]
{
	rgb color <- #purple;
	int glow_rad <- 0 update: (glow_rad + 1) mod 3 + 3;
	
	string genre <- music_genres at rnd(length(music_genres) - 1);
	
	int skill_level <- rnd(5);
	bool is_performing <- false;
	float time_to_perform;
	int performance_duration <- 30;
	
	init
	{
		speed <- agent_speed;
	}
	
	reflex wander when: !is_performing
	{
		do wander amplitude: 3;
	}
	
	reflex find_audience when: !is_performing
	{
		list<Guest> nearbyGuests <- Guest where(each.location distance_to(location) < 20);
		if (length(nearbyGuests) > 10 and time > time_to_perform + performance_duration + 30)
		{		
			is_performing <- true;	
			time_to_perform <- time + 1;
		}
	}
	
	reflex perform when: is_performing and time < time_to_perform + performance_duration and time >= time_to_perform
	{
		
	}
	
	reflex stop_perform when: time > time_to_perform + performance_duration
	{
		is_performing <- false;
	}
	
	
	aspect base {
		draw box(1, 1, 2) color: color;
		draw box(3, 1, 3) color: color at: {location.x, location.y, location.z + 2};
		draw box(1, 1, 1) color: color at: {location.x, location.y, location.z + 5};
		
		if (is_performing)
		{
			draw circle(glow_rad) color: color empty: true;
			draw rectangle(2 * 10, 2 * 10) texture: "../includes/carpet.png";
		}
	}
}

species Janitor skills: [moving]
{
	rgb color <- #white;
	bool is_cleaning;
	float vision <- 10.0;
	
	Trash target;
	
	init
	{
		speed <- agent_speed;
	}
	
	reflex wander when: !is_cleaning
	{
		do wander amplitude: 5;
	}
	
	reflex find_trash when: target = nil or dead(target)
	{
		list<Trash> nearbyTrash <- Trash where(each.location distance_to(location) < vision);
		if (!empty(nearbyTrash))
		{
			target <- nearbyTrash closest_to(self);
		}
	}
	
	reflex goto_trash when: target != nil and !dead(target) and location != target.location
	{
		do goto target:target;
	}
	
	reflex clean_trash when: target != nil and !dead(target) and location = target.location
	{
		ask target
		{
			do die;
		}
		target <- nil;
	}
	
	aspect base {
		draw box(1, 1, 2) color: color;
		draw box(3, 1, 3) color: color at: {location.x, location.y, location.z + 2};
		draw box(1, 1, 1) color: color at: {location.x, location.y, location.z + 5};			
	}
}

species Trash
{
	aspect base {
		draw rectangle(5, 5) texture: "../includes/trash.png";
	}
}

species Building
{
	int capacity;
}

species Store parent: Building
{	
	int capacity <- 2;
	int size;
	int queue_direction;
	
	list<Guest> waitingGuests;
	list<Guest> nearbyGuests update: Guest where(location distance_to(each.location) < 5 and each.target_location = location and each.waiting_location = nil);
	
	init {
		if (location.y > 50) 
		{
			queue_direction <- -1;
		}
		else 
		{
			queue_direction <- 1;
		}
	}
	
	reflex update_waiting_list when: !empty(nearbyGuests)
	{		
		ask nearbyGuests 
		{			
			myself.waitingGuests <- myself.waitingGuests + self;
			int number_of_waiting_guests <- length(myself.waitingGuests);
			
			if (number_of_waiting_guests mod 2 = 0)
			{
				self.waiting_location <- { myself.location.x - 3, myself.location.y + myself.queue_direction * (10 + (number_of_waiting_guests / 2) * 3) };
			}
			else 
			{
				self.waiting_location <- { myself.location.x + 3, myself.location.y + myself.queue_direction * (10 + (number_of_waiting_guests / 2) * 3) };
			}
		}
	}
	
	
	reflex serve when: !empty(waitingGuests) and time mod 5 = 0 {
		list<Guest> guestsToServe <- copy_between(waitingGuests, 0, capacity) where (each.location = each.waiting_location);

		if (!empty(guestsToServe))
		{
			loop g over: guestsToServe
			{
				g.waiting_location <- nil;
				do give_service(g);
			}
						
			waitingGuests <- copy_between(waitingGuests, length(guestsToServe), length(waitingGuests));
			loop g2 over: waitingGuests {
				if (g2.waiting_location != nil)
				{
					g2.waiting_location <- {g2.waiting_location.x, g2.waiting_location.y - queue_direction * 3};
				}			
			}
		}
	}
	
	action give_service(Guest guest)
	{
		
	}
}

species FoodStore parent: Store
{
	action give_service(Guest guest)
	{
		ask guest
		{
			do consume_food;
		}	
	}
	
	aspect base {
		draw box(10, 12, 8) texture: "../includes/pizza_store.png";
		draw box(10, 12, 1) at: {location.x, location.y, location.z + 8} texture: "../includes/red_roof_texture.png";
	}
}

species DrinkStore parent: Store
{
	action give_service(Guest guest)
	{
		ask guest
		{
			do consume_drink;
		}	
	}
	
	aspect base {
		draw box(10, 12, 8) texture: "../includes/drink_store.png";
		draw box(10, 12, 1) at: {location.x, location.y, location.z + 8} texture: "../includes/blue_roof_texture.png";
	}
}

species InformationCenter parent: Building
{
	init 
	{
		location <- information_center_location;
	}
	
	reflex serve {
		list<Guest> nearbyGuests <- Guest where(each.target_location = location and each.location distance_to(location) < 2);
		if (!empty(nearbyGuests))
		{
			ask nearbyGuests
			{
				point foodStore <- (FoodStore at rnd(number_of_foodstore - 1)).location;
				point drinkStore <- (DrinkStore at rnd(number_of_drinkstore - 1)).location;
				
				do get_info_about_store(foodStore, drinkStore);				
			}
		}
	}
	
	aspect base {
		draw box(20, 12, 8) texture: "../includes/information_center.png";		
	}
}

species CelestialBody {
	string texture;
	float angle <- 0.0;
	
	reflex move {
		angle <- angle + 0.25;
		if (angle = 360) {
			angle <- 0.0;
		}
			
		location <- { location.x, 50 + sin(angle) * 70, cos(angle) * 70 };			
	}
	
	aspect base {
		draw sphere(10) at: location texture: texture;		
	}
}
species Sun parent: CelestialBody
{
	float angle <- 0.0;
	string texture <- "../includes/sun.png";
	
	init {
		location <- { 50, 50, 70 };
	}
}

species Moon parent: CelestialBody
{
	float angle <- 180.0;
	string texture <- "../includes/moon.png";
	
	init {
		location <- { 50, 50, -70 };
	}	
}

species Firework
{
	rgb color <- one_of([#red, #green, #blue, #yellow, #purple]);
	float height <- 0.0;
	float explode_height <- one_of([30, 35, 40, 45]);
	int exploding_step <- 0;
	bool is_exploding <- false;
	
	list<point> points;
	list<list<point>> explode_motions <- [
		[{-3, 0, 0}, {-6, 0, 0}],
		[{3, 0, 0}, {10, 0, 0}],
		[{0, -3, 0}, {0, -6, 0}],
		[{0, 3, 0}, {0, 6, 0}],
		[{0, 0, 0}, {-3, -3, 3}],
		[{0, 0, 0}, {-3, 3, 3}],
		[{0, 0, 0}, { 3, 3, 3}],
		[{0, 0, 0}, { 3, -3, 3}],
		[{0, 0, 0}, {-3, -3, -3}],
		[{0, 0, 0}, {-3, 3, -3}],
		[{0, 0, 0}, { 3, 3, -3}],
		[{0, 0, 0}, { 3, -3, -3}],
		[{0, 0, 3}, {0, 0, 6}],
		[{0, 0, -3}, {0, 0, -6}]
	];
	
	reflex fire when: is_exploding = false and enable_firework and int(time) mod 1440 > 720	
	{
		if (rnd(10) = 1)
		{
			is_exploding <- true;
		}
	}
	
	reflex exploding when: is_exploding and time mod 2 = 0
	{
		if (height = -1.0) {
			do prepare_explosion;
		}	
		else {
			do explode;
		}
	}
	
	action explode
	{
		list<point> new_points <- [];
		if (height < explode_height) {
			
			
			loop p over: points {
				new_points <- new_points + { p.x, p.y, p.z + 5.0};
			}
			points <- new_points;
			height <- height + 5.0;			
		}		
		else if (exploding_step < length(explode_motions[0])) {
						
			int i <- 0;
			loop p over: points {
				new_points <- new_points + { p.x + explode_motions[i][exploding_step].x, p.y + explode_motions[i][exploding_step].y, p.z + explode_motions[i][exploding_step].z };
				i <- i + 1;
			}
			points <- new_points;
			exploding_step <- exploding_step + 1;
			write "exploding " + exploding_step;
		}
		else {
			write "stop explosion";
			is_exploding <- false;
			height <- -1.0;
		}
	}
	
	action prepare_explosion {
		height <- 0.0;
		exploding_step <- 0;
		color <- one_of([#red, #green, #blue, #yellow, #purple]);
		explode_height <- one_of([30.0, 35.0, 40.0, 45.0]);
		
		int x <- rnd(50) + 20;
		int y <- rnd(50) + 20;
		
		points <- [
			{ x, y, 0 }, 
			{ x, y, 0 }, 
			{ x, y, 0 }, 
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 },
			{ x, y, 0 }		
		];
	}
		
	aspect base {
		if (is_exploding) 
		{
			loop p over: points
			{			
				draw sphere(0.5) at: p color: color;
			}
		}						
	}
}

experiment main type:gui
{	
	parameter "Number of guests: " var: number_of_guests min: 1 max: 50 category: "Agents";
	parameter "Number of thiefs: " var: number_of_thiefs min: 0 max: 10 category: "Agents";
	parameter "Number of guards: " var: number_of_guards min: 0 max: 5 category: "Agents";
	parameter "Number of artists: " var: number_of_artists min: 0 max: 5 category: "Agents";
	parameter "Number of janitors: " var: number_of_janitors min: 0 max: 10 category: "Agents";
	
	parameter "Number of food stores: " var: number_of_foodstore min: 1 max: 4 category: "Buildings";
	parameter "Number of drink stores: " var: number_of_drinkstore min: 1 max: 4 category: "Buildings";
	
	parameter "Enable social encounters" var: enable_social_encounters category: "Settings";
	parameter "Enable firework" var: enable_firework category: "Settings";
	
	output {
		
		display my_display type:opengl camera_pos: {-20, -20, 100} camera_look_pos: {50, 50, 0} {			
			image file:"../includes/floor_texture.jpg";
				
			species Guest aspect:base;
			species Thief aspect:base;
			species Guard aspect:base;
			species Artist aspect:base;
			species Janitor aspect:base;
			
			species InformationCenter aspect:base;
			species FoodStore aspect:base;
			species DrinkStore aspect:base;
			
			species Trash aspect:base;
			
			species Sun aspect:base;
			species Moon aspect:base;
			species Firework aspect:base;
			
			light 1 type:point position:{ 50, 50 + sin(0.25 * time) * 70, cos(0.25 * cycle) * 70} color:#red draw_light:true;			
		}	
		
		display my_chart{
			chart "Global Happiness" //displays at every step in plot
			{
				data "Happiness " value:Guest sum_of(each.happiness);
			}
		}
						
		monitor "Global Happiness" value: global_happiness;
	}		
} 


create TYPE location_type as enum('city','suburb','district');
create table location(
	id serial primary key,
	name varchar(50) not null,
	type location_type,
	part_of int references location(id)
);

create table car_model(
	model_id serial primary key,
	make varchar(50) not null,
	model varchar(50) not null,
	category varchar(25) not null,
	capacity decimal
);

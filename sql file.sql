--create TYPE location_type as enum('city','suburb','district');
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

create table address(
	addr_id serial primary key,
	street_no varchar(25),
	street_name varchar(25) not null,
	suburb varchar(25) not null,
	state char(25) not null,
	zip char(4) not null
);

create table car_bay(
	name varchar(50) primary key,
	addr_id int references address(addr_id),
	description varchar(254),
	pos_latitude float not null,
	pos_longitude float not null,
	location_id int references location(id)
);

create TYPE transimission AS enum('auto','manual');

create table car(
	regno char(8) primary key,
	bay varchar(50) references car_bay(name),
	name varchar(50) unique,
	year date,
	transim transimission,
	model_id int references car_model(model_id)
);



	
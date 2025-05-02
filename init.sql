-- Create a database
DROP DATABASE IF EXISTS travel_agency;

CREATE DATABASE travel_agency;
USE travel_agency;


-- Create tables
CREATE TABLE location (
    LocationID VARCHAR(100) PRIMARY KEY,
    City VARCHAR(100) NOT NULL,   
    StateProvince VARCHAR(100),
    Country VARCHAR(100) NOT NULL,    
    TimeZone VARCHAR(100) NOT NULL   
);


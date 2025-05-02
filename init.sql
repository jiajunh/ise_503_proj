-- Create a database
DROP DATABASE IF EXISTS travel_agency;

CREATE DATABASE travel_agency;
USE travel_agency;

/*
modifications:
location
    | delete TimeZone

schedule: merge with route
    | FrequencyType 
route:
    | ScheduledDeparture, and ScheduledArrival redundant
    | need a transpotation id?

vendor:
    | ContactEmail, Website unique? Not necessary

transportation:

plane:
    | aircraftmodel -> planemodel

ship: no need to more identify the types
    | ShipName ? not needed / null available

train: 
    | type: Sleeper??? 
    | PowerType not necesary, or can be merged in type
    | license plate

bus:
    | HasToilet: ???? already in type

car:
    | create_year

car_rental:
    | should keep schedule time and actual time together?
    | daily rate might not needed

travel_unit:

inusrance & trip_insurance can merge

user_rank:
    | rank? maybe another name eg: level
    | also add maximum

user:
    | -> user-account
    | LastLogin: not necessary, not use it
    | rank no delete ,just update

review:
    | TransactionID, review not need transaction
    | STATUS??
    | maybe just create, not allow modification
*/

-- Create tables
CREATE TABLE location (
    LocationID VARCHAR(100) PRIMARY KEY,
    City VARCHAR(100) NOT NULL,   
    StateProvince VARCHAR(100),
    Country VARCHAR(100) NOT 
    NULL  
);

CREATE TABLE `schedule` (
    ScheduleID VARCHAR(100) PRIMARY KEY,
    DepartureTime TIME,
    ArrivalTime TIME,
    BaseFare DECIMAL(10, 2) CHECK (BaseFare >= 0),
    TransportationType ENUM('Plane', 'Ferry', 'Train', 'Bus', 'Car'),
    FrequencyType ENUM('Daily', 'Weekly', 'Weekdays', 'Weekends'),
    SourceLocationID VARCHAR(100) NOT NULL,
    DestinationLocationID VARCHAR(100) NOT NULL,
    FOREIGN KEY (SourceLocationID) REFERENCES location(LocationID),
    FOREIGN KEY (DestinationLocationID) REFERENCES location(LocationID)
);

CREATE TABLE route (
    RouteID VARCHAR(100) PRIMARY KEY,
    ScheduledDeparture DATETIME NOT NULL,
    ScheduledArrival DATETIME NOT NULL,
    ActualDeparture DATETIME,        
    ActualArrival DATETIME,             
    STATUS ENUM('OnTime', 'Delayed', 'Cancelled') NOT NULL,
    DelayReason VARCHAR(255),
    ScheduleID VARCHAR(100) NOT NULL,  
    FOREIGN KEY (ScheduleID) REFERENCES SCHEDULE(ScheduleID),
    CHECK (ScheduledDeparture < ScheduledArrival),
    CHECK (
        (ActualDeparture IS NULL AND ActualArrival IS NULL) OR 
        (ActualDeparture < ActualArrival)
    )
);

CREATE TABLE vendor (
    VendorID VARCHAR(100) PRIMARY KEY,
    VendorName VARCHAR(255),
    ContactPhoneNumber VARCHAR(50),
    ContactEmail VARCHAR(255) UNIQUE,
    Website VARCHAR(255) UNIQUE,
    Street VARCHAR(255),
    City VARCHAR(100),
    StateProvince VARCHAR(100),
    Country VARCHAR(100),
    ZipCode VARCHAR(20),
    TYPE ENUM('Transportation', 'Accommodation', 'Insurance', 'Activity', 'Restaurant')
);

-- Transportation
CREATE TABLE transportation (
    TransportationID VARCHAR(100) PRIMARY KEY,
    VendorID VARCHAR(100) NOT NULL,
    TYPE ENUM('Plane', 'Ship', 'Train', 'Bus', 'Car'),
    Capacity INT CHECK (Capacity > 0),
    FOREIGN KEY (VendorID) REFERENCES vendor(VendorID)
);

CREATE TABLE plane (
    TransportationID VARCHAR(100) PRIMARY KEY,
    AircraftModel VARCHAR(100) NOT NULL,
    AirlineCode VARCHAR(10) NOT NULL,
    FlightNumber VARCHAR(10) NOT NULL,
    LuggagePolicy TEXT,
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID),
    UNIQUE (AirlineCode, FlightNumber)
);

CREATE TABLE ship (
    TransportationID VARCHAR(100) PRIMARY KEY,
    ShipType ENUM('Cruise', 'Ferry', 'Yacht', 'PassengerShip'),
    ShipName VARCHAR(100) NOT NULL,
    DeckCount TINYINT UNSIGNED CHECK (DeckCount BETWEEN 1 AND 20),
    Tonnage DECIMAL(10, 2),
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE train (
    TransportationID VARCHAR(100) PRIMARY KEY,
    TrainType ENUM('High-speed', 'Sleeper'),
    NumberOfCarriages INT CHECK (NumberOfCarriages > 0),
    PowerType ENUM('Electric', 'Diesel'),
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE bus (
    TransportationID VARCHAR(100) PRIMARY KEY,
    BusType ENUM('Ordinary', 'DoubleDecker', 'TouristBus'),
    HasToilet BOOLEAN DEFAULT FALSE,
    LicensePlate VARCHAR(50) UNIQUE,
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE car (
    TransportationID VARCHAR(100) PRIMARY KEY,
    Brand VARCHAR(100),
    Model VARCHAR(100),
    FuelType ENUM('Gasoline', 'Diesel', 'Electric', 'Hybrid'),
    TransmissionType ENUM('Automatic', 'Manual'),
    SeatNumber INT CHECK (SeatNumber > 0),
    `Year` INT CHECK (`Year` > 0),
    LicensePlate VARCHAR(50) UNIQUE,
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE car_rental (
    RentalID VARCHAR(100) PRIMARY KEY,
    TransportationID VARCHAR(100) NOT NULL,
    ScheduledPickup DATETIME,
    ScheduledDropoff DATETIME,
    ActualPickup DATETIME,
    ActualDropoff DATETIME,
    DailyRate DECIMAL(10, 2) CHECK (DailyRate >= 0),
    TotalCost DECIMAL(10, 2) CHECK (TotalCost >= 0),
    RentalStatus ENUM('Reserved', 'PickedUp', 'Returned', 'Cancelled'),
    FOREIGN KEY (TransportationID) REFERENCES car(TransportationID)
);

CREATE TABLE accident (
    AccidentID VARCHAR(100) PRIMARY KEY,
    TransportationID VARCHAR(100) NOT NULL,
    OccurrenceTime DATETIME,
    SeverityLevel INT CHECK (SeverityLevel BETWEEN 1 AND 5),
    DESCRIPTION TEXT,
    STATUS ENUM('Reported', 'Investigating', 'Resolved', 'Archived'),
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE travel_unit (
    TransportationID VARCHAR(100) NOT NULL,
    UnitNumber VARCHAR(100) NOT NULL,
    TYPE ENUM('Seat', 'Cabin', 'Berth', 'Compartment'),
    Class ENUM('Economy', 'Business', 'First', 'Sleeper', 'Standard'),
    IsAvailable BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (TransportationID, UnitNumber),
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE trip (
    TripID VARCHAR(100) PRIMARY KEY,
    TotalCost DECIMAL(10, 2) UNSIGNED NOT NULL,
    BookingTime DATETIME NOT NULL,
    STATUS ENUM('Planned', 'Booked', 'Ongoing', 'Completed', 'Cancelled'),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CHECK (StartDate < EndDate)
);

CREATE TABLE trip_route (
    TripID VARCHAR(100) NOT NULL,
    RouteID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TripID, RouteID),
    FOREIGN KEY (TripID) REFERENCES trip(TripID),
    FOREIGN KEY (RouteID) REFERENCES route(RouteID)
);

CREATE TABLE trip_unit (
    TripID VARCHAR(100) NOT NULL,
    TransportationID VARCHAR(100) NOT NULL,
    UnitNumber VARCHAR(100) NOT NULL,
    PRIMARY KEY (TripID, TransportationID, UnitNumber),
    FOREIGN KEY (TripID) REFERENCES trip(TripID),
    FOREIGN KEY (TransportationID, UnitNumber)
        REFERENCES travel_unit(TransportationID, UnitNumber)
);

CREATE TABLE insurance (
    InsuranceID VARCHAR(100) PRIMARY KEY,
    TYPE ENUM('Health', 'Travel', 'Accident', 'Luggage', 'Vehicle', 'Other'),
    CoverageAmount DECIMAL(10, 2) UNSIGNED NOT NULL,
    Premium DECIMAL(10, 2) UNSIGNED NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    VendorID VARCHAR(100) NOT NULL,
    FOREIGN KEY (VendorID) REFERENCES vendor(VendorID),
    CHECK (StartDate < EndDate)
);

CREATE TABLE trip_insurance (
    TripID VARCHAR(100) NOT NULL,
    InsuranceID VARCHAR(100) UNIQUE NOT NULL,
    PRIMARY KEY (TripID, InsuranceID),
    FOREIGN KEY (TripID) REFERENCES trip(TripID),
    FOREIGN KEY (InsuranceID) REFERENCES insurance(InsuranceID)
);

CREATE TABLE restaurant (
    RestaurantID VARCHAR(100) PRIMARY KEY,
    NAME VARCHAR(255),
    AvgPricePerPerson DECIMAL(10, 2) CHECK (AvgPricePerPerson >= 0),
    OpeningHours VARCHAR(50),
    Rating DECIMAL(2, 1) UNSIGNED CHECK (Rating BETWEEN 0.0 AND 5.0),
    AcceptsReservation BOOLEAN NOT NULL DEFAULT FALSE,
    VendorID VARCHAR(100),
    FOREIGN KEY (VendorID) REFERENCES vendor(VendorID) ON DELETE SET NULL
);

CREATE TABLE food (
    FoodID VARCHAR(100) NOT NULL,
    RestaurantID VARCHAR(100) NOT NULL,
    NAME VARCHAR(255),
    TYPE ENUM('MainCourse', 'Dessert', 'Drink', 'Appetizer', 'Other'),
    BasePrice DECIMAL(10, 2) UNSIGNED NOT NULL,
    PRIMARY KEY (FoodID, RestaurantID),
    FOREIGN KEY (RestaurantID) REFERENCES restaurant(RestaurantID)
);

CREATE TABLE activity (
    ActivityID VARCHAR(100) PRIMARY KEY,
    NAME VARCHAR(255),
    TYPE VARCHAR(100),
    Duration DECIMAL(5, 2) UNSIGNED NOT NULL,
    Price DECIMAL(10, 2) UNSIGNED NOT NULL,
    ContactPhone VARCHAR(50),
    Rating DECIMAL(2, 1) UNSIGNED CHECK (Rating BETWEEN 0.0 AND 5.0),
    OpeningHours VARCHAR(50),
    VendorID VARCHAR(100),
    FOREIGN KEY (VendorID) REFERENCES vendor(VendorID)
);

CREATE TABLE accommodation (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    TYPE ENUM('Hotel', 'Motel', 'Hostel'),
    Facilities TEXT,
    ContactPhone VARCHAR(50),
    Rating DECIMAL(2,1) UNSIGNED CHECK (Rating BETWEEN 0.0 AND 5.0),
    NumberOfRooms INT UNSIGNED NOT NULL,
    VendorID VARCHAR(100),
    FOREIGN KEY (VendorID) REFERENCES vendor(VendorID) ON DELETE SET NULL
);

CREATE TABLE hotel (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    StarRating INT CHECK (StarRating BETWEEN 1 AND 5),
    NumberOfFloors SMALLINT UNSIGNED NOT NULL,
    Brand VARCHAR(255),
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE motel (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    HasParking BOOLEAN NOT NULL DEFAULT TRUE,
    Is24HourReception BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID)
);

CREATE TABLE hostel (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    HasSharedRooms BOOLEAN NOT NULL DEFAULT TRUE,
    NumberOfBedsPerRoom INT UNSIGNED NOT NULL,
    HasCurfew BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE room (
    RoomNumber VARCHAR(50) NOT NULL,
    AccommodationID VARCHAR(100) NOT NULL,
    RoomType ENUM('Single', 'Double', 'Suite') NOT NULL,
    BedType ENUM('Single', 'Double') NOT NULL,
    BasePrice DECIMAL(10, 2) UNSIGNED NOT NULL,
    MaxOccupancy INT UNSIGNED NOT NULL,
    IsAvailable BOOLEAN NOT NULL DEFAULT TRUE,
    HasPrivateBathroom BOOLEAN NOT NULL DEFAULT FALSE,
    Facility TEXT,
    PRIMARY KEY (RoomNumber, AccommodationID),
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE user_rank (
    RankName VARCHAR(100) PRIMARY KEY,
    DiscountRate DECIMAL(3, 2) UNSIGNED CHECK (DiscountRate BETWEEN 0.00 AND 1.00),
    MinimumPoints INT UNSIGNED NOT NULL
);

CREATE TABLE `user` (
    UserID VARCHAR(100) PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Gender ENUM('Male', 'Female', 'Other'),
    BirthDate DATE,
    PhoneNumber VARCHAR(50) UNIQUE,
    Email VARCHAR(255) UNIQUE,
    Street VARCHAR(255),
    City VARCHAR(100),
    StateProvince VARCHAR(100),
    Country VARCHAR(100),
    ZipCode VARCHAR(20),
    RankName VARCHAR(100),
    RegistrationTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastLogin DATETIME,
    FOREIGN KEY (RankName) REFERENCES user_rank(RankName)
	ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE department (
    DepartmentID VARCHAR(100) PRIMARY KEY,
    DepartmentName VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE customer_service_agent (
    AgentID VARCHAR(100) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    DepartmentID VARCHAR(100),
    Email VARCHAR(255) UNIQUE,
    PhoneNumber VARCHAR(50) UNIQUE,
    AvailabilityStatus ENUM('Online', 'Busy', 'Offline') NOT NULL DEFAULT 'Offline',
    FOREIGN KEY (DepartmentID) REFERENCES department(DepartmentID)
);

CREATE TABLE message (
    MessageID VARCHAR(100) PRIMARY KEY,
    UserID VARCHAR(100) NOT NULL,
    AgentID VARCHAR(100) NOT NULL,
    STATUS ENUM('Open', 'InProgress', 'Closed', 'Escalated') NOT NULL DEFAULT 'Open',
    TYPE ENUM('Inquiry', 'Complaint', 'Feedback', 'TechnicalSupport'),
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ResolvedAt DATETIME,
    MessageText TEXT,
    FOREIGN KEY (UserID) REFERENCES `user`(UserID),
    FOREIGN KEY (AgentID) REFERENCES customer_service_agent(AgentID)
);

CREATE TABLE coupon (
    CouponID VARCHAR(100) PRIMARY KEY,
    CouponName VARCHAR(100),
    DiscountType ENUM('Percentage', 'FixedAmount'),
    DiscountValue DECIMAL(10,2) UNSIGNED NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    MinSpend DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
    ApplicableServices TEXT
);

CREATE TABLE tax (
    TaxID VARCHAR(100) PRIMARY KEY,
    NAME VARCHAR(100),
    Rate DECIMAL(5,4) UNSIGNED NOT NULL CHECK (Rate BETWEEN 0.0000 AND 1.0000)
);

CREATE TABLE `transaction` (
    TransactionID VARCHAR(100) PRIMARY KEY,
    TransactionType VARCHAR(50),
    TotalAmount DECIMAL(10, 2) UNSIGNED NOT NULL,
    Currency ENUM('USD', 'CNY', 'KRW', 'JPY', 'INR', 'EUR', 'GBP', 
		'CAD', 'AUD', 'SGD', 'HKD', 'MYR', 
		'THB', 'RUB', 'AED', 'CHF', 'NZD'),
    PaymentMethod ENUM('CreditCard', 'PayPal', 'ApplePay', 'Alipay', 'WeChatPay', 'GooglePay', 'BankTransfer'),
    STATUS ENUM('Pending', 'Completed', 'Failed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    CreatedAt DATETIME,
    UpdatedAt DATETIME,
    CouponID VARCHAR(100),
    FOREIGN KEY (CouponID) REFERENCES coupon(CouponID) ON DELETE SET NULL
);

CREATE TABLE transaction_tax (
    TransactionID VARCHAR(100) NOT NULL,
    TaxID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TransactionID, TaxID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (TaxID) REFERENCES tax(TaxID)
);

CREATE TABLE transaction_trip (
    TransactionID VARCHAR(100) PRIMARY KEY,
    TripID VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (TripID) REFERENCES trip(TripID)
);

CREATE TABLE transaction_room (
    TransactionID VARCHAR(100) NOT NULL,
    RoomNumber VARCHAR(50) NOT NULL,
    AccommodationID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TransactionID, RoomNumber, AccommodationID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (RoomNumber, AccommodationID) REFERENCES room(RoomNumber, AccommodationID)
);

CREATE TABLE transaction_car_rental (
    TransactionID VARCHAR(100) PRIMARY KEY,
    RentalID VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (RentalID) REFERENCES car_rental(RentalID)
);

CREATE TABLE transaction_activity (
    TransactionID VARCHAR(100) NOT NULL,
    ActivityID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TransactionID, ActivityID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (ActivityID) REFERENCES activity(ActivityID)
);

CREATE TABLE transaction_food (
    TransactionID VARCHAR(100) NOT NULL,
    FoodID VARCHAR(100) NOT NULL,
    RestaurantID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TransactionID, FoodID, RestaurantID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (FoodID, RestaurantID) REFERENCES food(FoodID, RestaurantID)
);

CREATE TABLE transaction_insurance (
    TransactionID VARCHAR(100) PRIMARY KEY,
    InsuranceID VARCHAR(100) NOT NULL,
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (InsuranceID) REFERENCES insurance(InsuranceID)
);

CREATE TABLE review (
    ReviewID VARCHAR(100) PRIMARY KEY,
    UserID VARCHAR(100) NOT NULL,
    TransactionID VARCHAR(100),
    Rating TINYINT UNSIGNED NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Title VARCHAR(200),
    Content TEXT,
    IsAnonymous BOOLEAN NOT NULL DEFAULT FALSE,
    STATUS ENUM('Pending', 'Approved', 'Flagged', 'Removed'),
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastModified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES `user`(UserID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID)
);
-- Create a database
DROP DATABASE IF EXISTS travel_agency;

CREATE DATABASE travel_agency;
USE travel_agency;

-- Create tables
CREATE TABLE location (
    LocationID VARCHAR(100) PRIMARY KEY,
    City VARCHAR(100) NOT NULL,   
    StateProvince VARCHAR(100),
    Country VARCHAR(100) NOT NULL 
);

CREATE TABLE insurance (
    InsuranceID VARCHAR(100) PRIMARY KEY,
    TYPE ENUM('Health', 'Travel', 'Accident', 'Luggage', 'Vehicle', 'Other'),
    CoverageAmount DECIMAL(10, 2) UNSIGNED NOT NULL,
    Premium DECIMAL(10, 2) UNSIGNED NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CHECK (StartDate <= EndDate)
);

-- Transportation
CREATE TABLE transportation (
    TransportationID VARCHAR(100) PRIMARY KEY,
    TYPE ENUM('Plane', 'Ship', 'Train', 'Bus', 'Car'),
    Capacity INT CHECK (Capacity > 0)
);

CREATE TABLE public_transport (
    TransportationID VARCHAR(100) PRIMARY KEY,
    Facility TEXT,
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE plane (
    TransportationID VARCHAR(100) PRIMARY KEY,
    PlaneModel VARCHAR(100) NOT NULL,
    AirlineCode VARCHAR(10) NOT NULL,
    FlightNumber VARCHAR(10) NOT NULL,
    FOREIGN KEY (TransportationID) REFERENCES public_transport(TransportationID),
    UNIQUE (AirlineCode, FlightNumber)
);

CREATE TABLE ship (
    TransportationID VARCHAR(100) PRIMARY KEY,
    ShipType ENUM('Cruise', 'Ferry', 'Yacht', 'PassengerShip'),
    DeckCount TINYINT UNSIGNED CHECK (DeckCount BETWEEN 1 AND 20),
    Tonnage DECIMAL(10, 2),
    FOREIGN KEY (TransportationID) REFERENCES public_transport(TransportationID)
);

CREATE TABLE train (
    TransportationID VARCHAR(100) PRIMARY KEY,
    TrainType ENUM('High-speed', 'Ordinary'),
    NumberOfCarriages INT CHECK (NumberOfCarriages > 0),
    FOREIGN KEY (TransportationID) REFERENCES public_transport(TransportationID)
);

CREATE TABLE bus (
    TransportationID VARCHAR(100) PRIMARY KEY,
    BusType ENUM('Ordinary', 'DoubleDecker', 'TouristBus'),
    LicensePlate VARCHAR(50) UNIQUE,
    FOREIGN KEY (TransportationID) REFERENCES public_transport(TransportationID)
);

CREATE TABLE car (
    TransportationID VARCHAR(100) PRIMARY KEY,
    Brand VARCHAR(100),
    Model VARCHAR(100),
    FuelType ENUM('Gasoline', 'Diesel', 'Electric', 'Hybrid'),
    TransmissionType ENUM('Automatic', 'Manual'),
    SeatNumber INT CHECK (SeatNumber > 0),
    CreateYear YEAR,
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
    TYPE ENUM('Seat', 'Cabin'),
    Class ENUM('Economy', 'Business', 'First'),
    IsAvailable BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (TransportationID, UnitNumber),
    FOREIGN KEY (TransportationID) REFERENCES transportation(TransportationID)
);

CREATE TABLE route (
    RouteID VARCHAR(100) PRIMARY KEY,
    ScheduledDeparture DATETIME NOT NULL,
    ScheduledArrival DATETIME NOT NULL,
    ActualDeparture DATETIME,        
    ActualArrival DATETIME,             
    STATUS ENUM('OnTime', 'Delayed', 'Cancelled') NOT NULL,
    DelayReason VARCHAR(255),
    SourceLocationID VARCHAR(100) NOT NULL,
    DestinationLocationID VARCHAR(100) NOT NULL,
    BaseFare DECIMAL(10, 2) CHECK (BaseFare >= 0),
    TransportationID VARCHAR(100) NOT NULL,
    FOREIGN KEY (TransportationID) REFERENCES public_transport(TransportationID),
    FOREIGN KEY (SourceLocationID) REFERENCES location(LocationID),
    FOREIGN KEY (DestinationLocationID) REFERENCES location(LocationID),
    CHECK (ScheduledDeparture < ScheduledArrival),
    CHECK (
        (ActualDeparture IS NULL AND ActualArrival IS NULL) OR 
        (ActualDeparture < ActualArrival)
    )
);

CREATE TABLE trip (
    TripID VARCHAR(100) PRIMARY KEY,
    TotalCost DECIMAL(10, 2) UNSIGNED NOT NULL,
    BookingTime DATETIME NOT NULL,
    STATUS ENUM('Planned', 'Booked', 'Ongoing', 'Completed', 'Cancelled'),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    InsuranceID VARCHAR(100),
    CHECK (StartDate <= EndDate),
    FOREIGN KEY (InsuranceID) REFERENCES insurance(InsuranceID)
);

CREATE TABLE trip_route (
    TripID VARCHAR(100) NOT NULL,
    RouteID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TripID, RouteID),
    FOREIGN KEY (TripID) REFERENCES trip(TripID),
    FOREIGN KEY (RouteID) REFERENCES route(RouteID)
);

CREATE TABLE route_unit (
    RouteID VARCHAR(100) NOT NULL,
    TransportationID VARCHAR(100) NOT NULL,
    UnitNumber VARCHAR(100) NOT NULL,
    PRIMARY KEY (RouteID, TransportationID, UnitNumber),
    FOREIGN KEY (RouteID) REFERENCES route(RouteID),
    FOREIGN KEY (TransportationID, UnitNumber)
        REFERENCES travel_unit(TransportationID, UnitNumber)
);

CREATE TABLE restaurant (
    RestaurantID VARCHAR(100) PRIMARY KEY,
    NAME VARCHAR(255),
    AvgPricePerPerson DECIMAL(10, 2) CHECK (AvgPricePerPerson >= 0),
    OpeningHours VARCHAR(50),
    Rating DECIMAL(2, 1) UNSIGNED CHECK (Rating BETWEEN 0.0 AND 5.0),
    AcceptsReservation BOOLEAN NOT NULL DEFAULT FALSE,
    LocationID VARCHAR(100),
    FOREIGN KEY (LocationID) REFERENCES location(LocationID) ON DELETE SET NULL
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
    LocationID VARCHAR(100),
    FOREIGN KEY (LocationID) REFERENCES location(LocationID)
);

CREATE TABLE accommodation (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    TYPE ENUM('Room_Based', 'Whole_Unit') NOT NULL,
    Facilities TEXT,
    ContactPhone VARCHAR(50),
    Rating DECIMAL(2,1) UNSIGNED CHECK (Rating BETWEEN 0.0 AND 5.0),
    NumberOfRooms INT UNSIGNED NOT NULL,
    LocationID VARCHAR(100),
    FOREIGN KEY (LocationID) REFERENCES location(LocationID) ON DELETE SET NULL
);

CREATE TABLE hotel (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    HasLaundryService BOOLEAN NOT NULL DEFAULT FALSE,
    NumberOfRooms INT UNSIGNED NOT NULL,
    ReceptionAvailable BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE bnb (
    AccommodationID VARCHAR(100) PRIMARY KEY,
    MaxOccupancy INT UNSIGNED NOT NULL,
    Bathrooms INT UNSIGNED NOT NULL,
    Bedrooms INT UNSIGNED NOT NULL,
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE room (
    RoomNumber VARCHAR(50) NOT NULL,
    AccommodationID VARCHAR(100) NOT NULL,
    RoomType ENUM('Single', 'Double', 'Suite') NOT NULL,
    BedType ENUM('Single', 'Double') NOT NULL,
    BasePrice DECIMAL(10, 2) UNSIGNED NOT NULL CHECK (BasePrice >= 0),
    MaxOccupancy INT UNSIGNED NOT NULL,
    IsAvailable BOOLEAN NOT NULL DEFAULT TRUE,
    HasPrivateBathroom BOOLEAN NOT NULL DEFAULT FALSE,
    Facility TEXT,
    PRIMARY KEY (AccommodationID, RoomNumber),
    FOREIGN KEY (AccommodationID) REFERENCES hotel(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE acc_booking (
    BookingID VARCHAR(100) PRIMARY KEY,
    BookingTime DATETIME NOT NULL,
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    STATUS ENUM('Pending', 'Confirmed', 'Cancelled', 'Completed') NOT NULL,
    TotalCost DECIMAL(10, 2) UNSIGNED NOT NULL,
    AccommodationID VARCHAR(100) NOT NULL,
    FOREIGN KEY (AccommodationID) REFERENCES accommodation(AccommodationID) ON DELETE CASCADE
);

CREATE TABLE booking_room (
    BookingID VARCHAR(100) NOT NULL,
    AccommodationID VARCHAR(100) NOT NULL,
    RoomNumber VARCHAR(50) NOT NULL,
    PRIMARY KEY (BookingID, AccommodationID, RoomNumber),
    FOREIGN KEY (BookingID) REFERENCES acc_booking(BookingID) ON DELETE CASCADE,
    FOREIGN KEY (AccommodationID, RoomNumber) REFERENCES room(AccommodationID, RoomNumber) ON DELETE CASCADE
);

CREATE TABLE user_level (
    LevelName VARCHAR(100) PRIMARY KEY,
    DiscountRate DECIMAL(3, 2) UNSIGNED CHECK (DiscountRate BETWEEN 0.00 AND 1.00),
    MinPoints INT UNSIGNED NOT NULL,
    MaxPoints INT UNSIGNED NOT NULL
);

CREATE TABLE user_account (
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
    LevelName VARCHAR(100),
    RegistrationTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastLogin DATETIME,
    FOREIGN KEY (LevelName) REFERENCES user_level(LevelName)
	ON DELETE SET NULL
        ON UPDATE CASCADE
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
    Currency ENUM('USD', 'CNY', 'KRW', 'JPY', 'INR', 'EUR'),
    PaymentMethod ENUM('CreditCard', 'PayPal', 'ApplePay','Cash'),
    STATUS ENUM('Pending', 'Completed', 'Failed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    TargetID VARCHAR(100),
    TargetType ENUM('Trip', 'Accommodation', 'Restaurant', 'Car_Rental', 'Activity', 'Insurance'),
    CreatedAt DATETIME,
    UpdatedAt DATETIME,
    CouponID VARCHAR(100),
    UserID VARCHAR(100) NOT NULL,
    FOREIGN KEY (UserID) REFERENCES user_account(UserID),
    FOREIGN KEY (CouponID) REFERENCES coupon(CouponID) ON DELETE SET NULL
);

CREATE TABLE transaction_tax (
    TransactionID VARCHAR(100) NOT NULL,
    TaxID VARCHAR(100) NOT NULL,
    PRIMARY KEY (TransactionID, TaxID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID),
    FOREIGN KEY (TaxID) REFERENCES tax(TaxID)
);

CREATE TABLE review (
    ReviewID VARCHAR(100) PRIMARY KEY,
    UserID VARCHAR(100) NOT NULL,
    TransactionID VARCHAR(100),
    Rating TINYINT UNSIGNED NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Title VARCHAR(200),
    Content TEXT,
    IsAnonymous BOOLEAN NOT NULL DEFAULT FALSE,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastModified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES user_account(UserID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID)
);

CREATE TABLE customer_service_agent (
    AgentID VARCHAR(100) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(255) UNIQUE,
    PhoneNumber VARCHAR(50) UNIQUE,
    AvailabilityStatus ENUM('Online', 'Busy', 'Offline') NOT NULL DEFAULT 'Offline'
);

CREATE TABLE message (
    MessageID VARCHAR(100) PRIMARY KEY,
    UserID VARCHAR(100) NOT NULL,
    AgentID VARCHAR(100),
    STATUS ENUM('Open', 'InProgress', 'Closed', 'Escalated') NOT NULL DEFAULT 'Open',
    TYPE ENUM('Inquiry', 'Complaint', 'Feedback', 'TechnicalSupport') NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ResolvedAt DATETIME,
    MessageText TEXT,
    TransactionID VARCHAR(100),
    FOREIGN KEY (UserID) REFERENCES user_account(UserID),
    FOREIGN KEY (AgentID) REFERENCES customer_service_agent(AgentID),
    FOREIGN KEY (TransactionID) REFERENCES `transaction`(TransactionID)
);
# 📊 Streaming Services Database - SQL Repository

This repository contains a structured set of SQL scripts for managing a streaming services database, covering everything from table creation to advanced queries and testing.

## 🏗️ Database Structure & Scripts

### 1. 📜 CreareTabele.sql – Database Schema Definition

Defines the structure of the database:
-  🧑‍💻 Utilizatori (Users) – Stores user details. Connected to DateCard, Vizualizari, Recenzii, AbonamenteUtilizatori, and Dispozitive (tracks subscriptions, payments, and activity).

-  💳 DateCard (Card Details) – Stores payment details for users. Linked to Utilizatori (each user has one card).

-  🎥 ContinutMedia (Media Content) – Stores movies and shows. Linked to Episoade, Vizualizari, and Recenzii (tracks episodes, viewing history, and reviews).

-  📺 Episoade (Episodes) – Stores episodes for TV shows. Linked to ContinutMedia (each episode belongs to a show) and Vizualizari (tracks user activity).

-  👀 Vizualizari (Viewing History) – Logs what users watch. Linked to Utilizatori, ContinutMedia, and Episoade (records viewing activity).

-  ⭐ Recenzii (Reviews) – Stores user ratings and comments. Linked to Utilizatori and ContinutMedia (users review content).

-  📱 Dispozitive (Devices) – Tracks devices used for streaming. Linked to Utilizatori (each user has multiple devices).

-  🛒 ServiciiDeStreaming (Streaming Services) – Stores available platforms (Netflix, HBO, etc.). Linked to AbonamenteUtilizatori (tracks user subscriptions).

-  📄 TipuriDeAbonamente (Subscription Plans) – Defines subscription types. Linked to AbonamenteUtilizatori (subscriptions reference a plan).

-  📜 AbonamenteUtilizatori (User Subscriptions) – Tracks user subscriptions. Linked to Utilizatori, ServiciiDeStreaming, and TipuriDeAbonamente (manages user plans).

-  💰 Facturi (Billing & Payments) – Tracks invoices. Linked to Utilizatori and AbonamenteUtilizatori (manages payments for subscriptions).  

### 2.1. 📥 PopulareTabele.sql – Data Population Script

-  Inserts sample data into the tables for testing and development.


### 2.2. 🔍 Interogari.sql – SQL Queries for Data Retrieval

-  Contains complex SELECT queries to extract insights from the database.

-  Retrieves user activity, subscription details, and content popularity statistics.

### 3. ⚙️ ScriptSQL.sql – Comprehensive Database Setup

-  A one-stop script that include table creation, data insertion, and queries.

-  Simplifies the process of setting up and using the database.

### 4. 🛠️ TestareBD.sql – Database Testing & Validation

-  Ensures the correct functionality of the database by running test queries.

-  Helps validate relationships, constraints, and data integrity.

### 5. 📝 OperatiiCRUD.sql – CRUD Operations (Create, Read, Update, Delete)

-  Provides SQL commands for managing records within the database.

-  Enables adding, modifying, and removing users, subscriptions, and content.

## 🌟 Key Highlights

-  *Well-Structured Database* – Organized schema with clearly defined relationships.

-  *Comprehensive SQL Operations* – Covers CRUD, queries, testing, and optimizations.

-  *Data Integrity & Validation* – Ensures correct constraints and relationships.

-  *Real-World Application* – Simulates a streaming platform's database structure.

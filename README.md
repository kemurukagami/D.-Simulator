# COMPSCI 310 Project: D. Simulator - A Database-Driven Detective Game

D. Simulator is a detective simulation game where the core logic, AI, and dynamic world events are managed entirely by a relational database (SQLite). The player assumes the role of a chief of police, using database-driven tools to analyze data, track suspects, and apprehend a killer in a simulated city.

This project was built to explore advanced database concepts, demonstrating how complex, stateful, and dynamic logic can be implemented directly in SQL rather than at the application level.

[Project Report](<docs/D-Simulator Report/D_Simulator.pdf>)

[Presentation Slides](docs/Presentation.pdf)

<p align="center">
  <img src="docs/D-Simulator Report/game_window.png" width="500">
</p>

# Core Features

## 1. Dynamic Pathfinding via Recursive SQL Triggers

A primary technical challenge was generating unique daily paths for hundreds of inhabitants (including the killer) in a graph-based city, given that SQLite lacks support for stored procedures. This was solved using a two-step process implemented entirely with **recursive triggers**.

1.  **Dijkstra's All-Pairs Shortest Path:**
    * At the start of each round, the system calculates the shortest path between all vertex pairs.
    * This is implemented using an `AFTER UPDATE` trigger on a temporary `dist` table.
    * Updating a vertex's distance to 0 (for itself) initiates a recursive cascade that updates its neighbors' distances, effectively executing Dijkstra's algorithm natively in SQL.

2.  **Randomized Inhabitant Path Generation:**
    * Once shortest paths are known, a unique, constrained random path is generated for each inhabitant (e.g., from `home` to `work` between 8:00 AM and 9:00 AM).
    * This is also implemented using a recursive `AFTER INSERT` trigger on a `loc_time` table.
    * The trigger randomly selects a valid neighboring vertex (that can still reach the destination in time) and a random wait time. It then inserts this new `(inhabitant_id, vertex_id, arrive_time, leave_time)` tuple, which immediately re-fires the trigger, continuing the random walk until the final destination is reached.

## 2. Dynamic AI & Victim Selection Query

The killer's *modus operandi* is not hard-coded. It is determined by a complex `Victim Selection` query that runs each round.

* **Path Intersection:** The query first finds all potential victims by performing a self-join on the `loc_time` table. This identifies any `(inhabitant_id, vertex_id)` pairs that share the same location at the same time as the killer, calculating the exact window of temporal overlap.
* **AI-Driven Weighting:** The query then joins these potential victims with the `killer_chara` (killer characteristics) table. A complex `CASE` statement is used to "weigh" each potential victim based on whether they match the killer's specific preferences (e.g., "low income," "neighbor," "colleague").
* **Final Selection:** The inhabitant with the highest cumulative weight (most matching characteristics) who intersects with the killer's path is selected as the victim for that round.

## 3. Analytical Queries & Views for Gameplay

The player's investigative tools are direct SQL queries abstracted by the UI.

* **`CREATE VIEW commonality`:** To help the player profile the killer, a SQL view (`commonality`) is created. This view uses a series of `UNION ALL` statements to unpivot victim data (gender, income, workplace, etc.) into a single `(attribute_name, attribute_value)` format. It then groups by these pairs to find and display common attributes shared among all victims (e.g., "income_level: low" - 3 occurrences).
* **`Witness Count` Query:** This query checks for temporal overlaps between a given inhabitant and all other inhabitants at a specific vertex, simulating a witness count for that location.

# Database Schema

The system is built on a normalized relational schema that defines the city, its inhabitants, and the game's state.

* `inhabitant`: Stores all character data, including `home_building_id`, `workplace_id`, and dynamic state flags like `dead` and `custody`.
* `vertex` / `edge`: Defines the city map as a weighted, directed graph.
* `building` / `workplace` / `home`: Defines key locations that act as pathfinding sources and destinations.
* `killer` / `killer_chara`: Defines the killer's AI profile and target preferences.
* `relationship`: Stores the social web (e.g., "Friend," "Colleague," "Relative") between inhabitants.
* `status`: A singleton table that tracks the global game state, such as the current day and the identity of the killer, enabling save/load functionality.

<p align="center">
  <img src="docs/D-Simulator Report/Final_Database_Schema.png" width="800">
</p>

# Application & UI

The front-end is a lightweight client built in Python using the *DearPyGui* library. It provides a user interface for the player to interact with the database.

* **Interactive Map:** A scrollable map displays all vertices, edges (with travel cost), and buildings.
* **Database Search:** A "Query Inhabitants" window allows the player to filter and search the `inhabitant` table by attributes like occupation, gender, or name.
* **Investigative Tools:** Players can:
    * Click buildings to see details and a "Witness List" (from the `Witness Count` query).
    * Click inhabitants to see their relationships, details, and mark them as a `Suspect`.
    * View the `Victim` window to see the `commonality` view.
    * Place a `Lockdown` on a building, which disables its associated `edge` tuples for the next round's pathfinding.
* **Game State Management:** The UI provides "Save Game" and "Load Game" functionality, which serializes/deserializes the database state.# D. Simulator: A Database-Driven Detective Game

# Building

Build the project and output the package in the `dist` directory:
```bash
pip install build
python3 -m build
```

# Testing

To test the project module locally, create a virtual environment first:
```bash
pip install virtualenv
python3 -m venv .venv
```

Then, activate the virtual environment:
```bash
source .venv/bin/activate # For Unix-like operating systems
.venv\bin\activate.bat    # For Windows
```

Finally, do a editable install using pip:
```bash
pip install -e .
```

Run the program by executing:
```bash
dsimulator
```

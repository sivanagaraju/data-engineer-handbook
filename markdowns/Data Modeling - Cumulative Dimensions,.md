# Data Modeling - Cumulative Dimensions, Struct, and Array - Day 1 Lab

## Introduction

- **Welcome to Dimensional Data Modeling Day One Lab**
  - Hands-on exercise to master concepts of `struct` and `array` in PostgreSQL.
  - **Preparation Steps**:
    - Clone the GitHub repository (link provided in the description).
    - Ensure Docker is installed to spin up a PostgreSQL instance.
    - Install a SQL client:
      - **DataGrip**: Used in the lab; 30-day free trial.
      - **Alternatives**:
        - **DBeaver**: Free and open-source.
        - **DBVisualizer**: Free version available.
  - **Additional Resources**:
    - Join the Data Expert community for further learning (link provided).

## The Data Set

### Description of the `player_seasons` Table

- **Overview**:
  - Contains NBA player data.
  - Each row represents a player for a specific season.
- **Attributes**:
  - **Player-Level Attributes** (do not change across seasons):
    - `player_name`
    - `height`
    - `college`
    - `country`
    - `draft_year`
    - `draft_round`
    - `draft_number`
  - **Season-Level Attributes** (change each season):
    - `season`
    - `GP` (Games Played)
    - `points`
    - `Reb` (Rebounds)
    - `assist`
    - Other detailed stats (ignored for simplicity in the lab).

### Issues with the Current Data Model

- **Temporal Problem**:
  - Duplication of player-level data across multiple seasons.
  - Causes inefficiencies when joining with downstream tables.
  - Leads to shuffling and loss of compression during queries.

## Creating a Struct Data Type

### Identifying Attributes

- **Goal**: Separate player-level data from season-level data.
- **Player-Level Attributes**:
  - Remain constant; to be stored directly in the new `players` table.
- **Season-Level Attributes**:
  - Vary by season; to be encapsulated within a `struct` and stored as an array.

### Defining the `season_stats` Struct

```sql
CREATE TYPE season_stats AS (
  season INTEGER,
  GP INTEGER,
  points REAL,
  Reb REAL,
  assist REAL
);
```

- **Explanation**:
  - `season`: Year of the season.
  - `GP`: Games played in the season.
  - `points`: Average points per game.
  - `Reb`: Average rebounds per game.
  - `assist`: Average assists per game.
- **Purpose**: Group season-level stats into a single composite type.

## Creating the `players` Table

### Defining the Table Schema

```sql
CREATE TABLE players (
  player_name TEXT,
  height TEXT,
  college TEXT,
  country TEXT,
  draft_year TEXT,
  draft_round TEXT,
  draft_number TEXT,
  season_stats season_stats[],
  current_season INTEGER,
  PRIMARY KEY (player_name, current_season)
);
```

- **Columns**:
  - **Player-Level Attributes**: Stored directly.
  - **`season_stats`**: An array of `season_stats` structs.
  - **`current_season`**: Tracks the latest season in the cumulation.
- **Primary Key**:
  - Composite of `player_name` and `current_season` to ensure uniqueness.

## Cumulation Logic

### Understanding Cumulation

- **Objective**: Build a cumulative table that holds all historical data for each player.
- **Approach**:
  - Use full outer joins to merge today's data with cumulative data from yesterday.
  - Use `COALESCE` to handle nulls and merge attributes.

### Initializing Cumulation

- **Determine Starting Season**:

  ```sql
  SELECT MIN(season) FROM player_seasons;
  -- Result: 1996
  ```

- **Set Up CTEs for `today` and `yesterday`**:

  ```sql
  WITH yesterday AS (
    SELECT * FROM players WHERE current_season = 1995
  ),
  today AS (
    SELECT * FROM player_seasons WHERE season = 1996
  )
  ```

### Full Outer Join and Coalescing Values

- **Perform Full Outer Join**:

  ```sql
  SELECT
    COALESCE(t.player_name, y.player_name) AS player_name,
    COALESCE(t.height, y.height) AS height,
    COALESCE(t.college, y.college) AS college,
    COALESCE(t.country, y.country) AS country,
    COALESCE(t.draft_year, y.draft_year) AS draft_year,
    COALESCE(t.draft_round, y.draft_round) AS draft_round,
    COALESCE(t.draft_number, y.draft_number) AS draft_number,
    -- Season stats and current season to be added next
  FROM
    today t
  FULL OUTER JOIN
    yesterday y
  ON
    t.player_name = y.player_name;
  ```

- **Explanation**:
  - Merges `today` and `yesterday` data on `player_name`.
  - Uses `COALESCE` to handle null values, preferring today's data.

## Building the Seasons Array

### Constructing the `season_stats` Array

- **Handling Different Scenarios**:
  - **New Players**: Not present in `yesterday`.
  - **Continuing Players**: Present in both `today` and `yesterday`.
  - **Retired Players**: Present in `yesterday` but not in `today`.

- **Building the Array**:

  ```sql
  CASE
    WHEN y.season_stats IS NULL THEN
      ARRAY[
        ROW(t.season, t.GP, t.points, t.Reb, t.assist)::season_stats
      ]
    WHEN t.season IS NOT NULL THEN
      y.season_stats || ARRAY[
        ROW(t.season, t.GP, t.points, t.Reb, t.assist)::season_stats
      ]
    ELSE
      y.season_stats
  END AS season_stats,
  ```

- **Explanation**:
  - **First Entry**: For new players, create an array with the current season stats.
  - **Appending**: For continuing players, concatenate the new season stats to the existing array.
  - **Carrying Forward**: For retired players, carry forward the existing `season_stats` without changes.

### Updating `current_season`

- **Determining the Latest Season**:

  ```sql
  COALESCE(t.season, y.current_season + 1) AS current_season,
  ```

- **Explanation**:
  - If the player played this season (`t.season` is not null), use `t.season`.
  - Else, increment `y.current_season` by 1 to keep track of the years.

## Inserting Data and Cumulating

### Loading Initial Data

- **Insert Cumulated Data into `players` Table**:

  ```sql
  INSERT INTO players
  SELECT
    -- All columns from the full outer join query
  FROM
    -- The full outer join query as described earlier
  ```

- **Note**:
  - Initial run with `current_season = 1996` and no prior data (`yesterday` is null).

### Iterating Over Seasons

- **Update CTEs for Each Season**:

  ```sql
  -- For season 1997
  WITH yesterday AS (
    SELECT * FROM players WHERE current_season = 1996
  ),
  today AS (
    SELECT * FROM player_seasons WHERE season = 1997
  )
  ```

- **Repeat Insertion**:
  - Run the cumulation query for each subsequent season, updating `yesterday` and `today` accordingly.
  - Example seasons: 1997, 1998, 1999, 2000, 2001.

### Example: Michael Jordan

- **Querying Michael Jordan's Data**:

  ```sql
  SELECT * FROM players WHERE player_name = 'Michael Jordan';
  ```

- **Observations**:
  - `season_stats` array shows a gap between 1997 and 2001.
  - Reflects his retirement and return.

## Unnesting and Querying the Data

### Using `UNNEST` to Explode Arrays

- **Flattening the Data**:

  ```sql
  SELECT
    player_name,
    season_stat.*
  FROM
    players,
    UNNEST(season_stats) AS season_stat;
  ```

- **Accessing Struct Fields**:

  - Ensure proper casting if necessary.
  - Access fields like `season_stat.season`, `season_stat.points`, etc.

### Handling PostgreSQL Syntax Nuances

- **Casting and Field Access**:

  ```sql
  -- Using a CTE for clarity
  WITH unnested AS (
    SELECT
      player_name,
      UNNEST(season_stats) AS season_stat
    FROM
      players
  )
  SELECT
    player_name,
    (season_stat).season,
    (season_stat).points,
    (season_stat).Reb,
    (season_stat).assist
  FROM
    unnested;
  ```

- **Explanation**:
  - Wrap `season_stat` in parentheses when accessing fields.
  - PostgreSQL requires specific syntax for accessing fields from composite types.

## Advantages of Cumulative Table Design

### Preserving Sorting and Compression

- **Compression Benefits**:
  - Keeping data sorted aids in compression algorithms like run-length encoding.
  - Avoids shuffling that disrupts data ordering.

### Efficient Querying Without `GROUP BY`

- **Direct Access to Data**:
  - Historical analysis can be performed without aggregation.
  - Queries are faster due to reduced computational overhead.

- **Example Query**:

  ```sql
  SELECT
    player_name,
    -- Accessing first and latest season stats
    (season_stats[1]).points AS first_season_points,
    (season_stats[array_length(season_stats, 1)]).points AS latest_season_points
  FROM
    players;
  ```

- **No `GROUP BY` Required**:
  - Data is structured to allow direct access to required information.

## Adding Additional Columns

### Defining New Types and Columns

- **Creating `scoring_class` Enum**:

  ```sql
  CREATE TYPE scoring_class AS ENUM ('star', 'good', 'average', 'bad');
  ```

- **Updating the `players` Table Schema**:

  ```sql
  CREATE TABLE players (
    -- Existing columns...
    scoring_class scoring_class,
    years_since_last_season INTEGER,
    current_season INTEGER,
    PRIMARY KEY (player_name, current_season)
  );
  ```

### Computing `scoring_class`

- **Based on Points Per Game**:

  ```sql
  CASE
    WHEN t.points > 20 THEN 'star'
    WHEN t.points > 15 THEN 'good'
    WHEN t.points > 10 THEN 'average'
    ELSE 'bad'
  END::scoring_class AS scoring_class,
  ```

- **Handling Retired Players**:

  ```sql
  COALESCE(
    CASE
      WHEN t.season IS NOT NULL THEN
        -- Scoring class logic
    END,
    y.scoring_class
  ) AS scoring_class,
  ```

### Computing `years_since_last_season`

- **Calculating Years Since Last Active Season**:

  ```sql
  CASE
    WHEN t.season IS NOT NULL THEN 0
    ELSE y.years_since_last_season + 1
  END AS years_since_last_season,
  ```

### Rebuilding the `players` Table

- **Process**:
  - Drop the existing `players` table.
  - Recreate it with the new schema.
  - Run the cumulation query for each season, inserting data.

## Performing Analytical Queries

### Finding the Most Improved Players

- **Calculating Improvement Ratio**:

  ```sql
  SELECT
    player_name,
    (season_stats[array_length(season_stats, 1)]).points AS latest_points,
    (season_stats[1]).points AS first_points,
    CASE
      WHEN (season_stats[1]).points = 0 THEN NULL
      ELSE (season_stats[array_length(season_stats, 1)]).points / (season_stats[1]).points
    END AS improvement_ratio
  FROM
    players
  ORDER BY
    improvement_ratio DESC;
  ```

- **Explanation**:
  - Access the first and latest points per game.
  - Calculate the ratio to determine improvement.
  - Handle division by zero cases.

### Filtering by `scoring_class`

- **Query for Top Players**:

  ```sql
  SELECT
    player_name,
    improvement_ratio
  FROM
    (
      -- Subquery with improvement calculation
    ) sub
  WHERE
    scoring_class = 'star'
  ORDER BY
    improvement_ratio DESC;
  ```

- **Result**:
  - Identifies players who improved the most among star players.
  - Examples include Tracy McGrady, Dirk Nowitzki, Kobe Bryant.

### Advantages of the Approach

- **No `GROUP BY` Needed**:
  - Directly access array elements without aggregation.
- **Performance Benefits**:
  - Queries are faster due to the absence of shuffling and grouping.
  - Highly parallelizable and efficient.

## Conclusion

- **Key Takeaways**:
  - **Cumulative Table Design**:
    - Efficiently stores historical data without duplication.
    - Simplifies historical and temporal analyses.
  - **Structs and Arrays**:
    - Organize complex data within tables.
    - Facilitate easy expansion and querying.
  - **Performance Improvements**:
    - Avoids heavy computations and shuffling.
    - Enables fast, scalable queries.
- **Final Thoughts**:
  - This approach demonstrates the power of thoughtful data modeling.
  - Encourages exploration of advanced SQL features to optimize data handling.
  - Emphasizes the importance of structuring data according to analytical needs.

---

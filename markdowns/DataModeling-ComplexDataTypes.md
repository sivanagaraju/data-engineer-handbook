# Dimensional Data Modeling - Complex Data Types and Cumulation

## Introduction

- **Overview**
  - First lecture of the DataExpert.io Free Boot Camp.
  - Focus on complex data types: `struct` and `array`.
    - **Array**: Think of it as a list within a column.
    - **Struct**: Think of it as a table within a table.
  - Importance of building compact data sets.
    - Example: At Airbnb, data sets were shrunk by over 95% using an array of structs.
  - Usability concerns with complex data types.
    - Harder to query and work with.
    - Knowing your data customer is critical.
  - Encouragement to learn more through the Data Expert Academy.

## Dimensions in Data Modeling

- **What is a Dimension?**
  - Attributes of an entity.
    - Examples: birthday, favorite food, city of residence, name.
  - Helps define the space or area in data.

- **Types of Dimensions**
  - **Identifier Dimensions**
    - Uniquely identify an entity.
    - Examples: user ID, social security number, device ID.
  - **Attributes**
    - Provide additional information about the entity.
    - Not critical for identification but useful for analysis.

- **Attribute Dimensions**
  - **Slowly Changing Dimensions**
    - Attributes that change over time.
    - Example: favorite food.
    - Time-dependent attributes.
  - **Fixed Dimensions**
    - Attributes that do not change.
    - Examples: birthday, manufacturer of a device.
    - Set in stone and unchangeable.

## Knowing Your Data Customer

- **Importance of Empathy**
  - Understanding who will use the data.
  - Modeling data according to the needs of the consumer.

- **Types of Data Consumers**
  - **Data Analysts and Data Scientists**
    - Need data that is easy to work with.
    - Prefer flat structures with decimal numbers and strings.
    - Avoid complex data types for usability.
  - **Data Engineers**
    - May consume data to join with other data sets.
    - Comfortable with nested types like structs and arrays.
    - Use complex data types to build master data sets.
  - **Machine Learning Models**
    - Require identifiers and flat, primitive feature columns.
    - Prefer consistent data types for model training.
  - **Customers (End Users)**
    - Should receive data as charts or visualizations.
    - Should not be given raw or complex data sets.

## OLTP vs. OLAP

- **Understanding the Difference**
  - **OLTP (Online Transaction Processing)**
    - Used in production systems.
    - Data is normalized to minimize duplication.
    - Involves primary keys, foreign keys, constraints.
    - Optimized for individual transactions.
  - **OLAP (Online Analytical Processing)**
    - Used for analytical purposes.
    - Data is often denormalized.
    - Focuses on aggregates and groups.
    - Optimized for queries over large data sets.

- **Mismatching Needs**
  - Modeling transactional systems like analytical systems can cause slow apps.
  - Modeling analytical systems like transactional systems can cause slow queries due to excessive joins.

- **Master Data as Middle Ground**
  - Combines aspects of both OLTP and OLAP.
  - Provides complete definitions for entities.
  - Used by data engineers to create downstream data sets.
  - Example: Combining 40 transactional tables into one master data table.

## Data Modeling Continuum

- **Layers of Data Modeling**
  - **Production Data (OLTP)**
    - Highly normalized.
    - Optimized for real-time transactions.
  - **Master Data**
    - Middle ground between OLTP and OLAP.
    - Provides completeness and denormalization.
  - **OLAP Cubes**
    - Denormalized data for analytical purposes.
    - Facilitates slice and dice operations.
  - **Metrics**
    - Aggregated data distilled into key numbers.
    - Example: Average listing price.

- **Understanding Each Layer**
  - Recognizing the role of each layer helps in effective data modeling.
  - Avoiding forcing one layer's modeling approach onto another.

## Cumulative Table Design

- **Concept**
  - Holding onto all historical data up to a point.
  - Combines today's data with yesterday's cumulative data.
  - Uses full outer joins and coalescing values.

- **Applications**
  - **Historical Analysis**
    - Tracking user activity over time without needing group by operations.
    - Example: Facebook's Dim All Users table for growth analytics.
  - **State Transition Tracking**
    - Analyzing transitions like churned, resurrected, or new users.
    - Comparing today's and yesterday's states.

- **Implementation Steps**
  1. **Full Outer Join**: Combine today's and yesterday's data on the identifier.
  2. **Coalesce IDs**: Merge IDs from both datasets to handle nulls.
  3. **Compute Cumulative Metrics**: Calculate metrics like days since last active.
  4. **Collect or Concatenate Data**: Aggregate historical data into arrays or structs.
  5. **Output Cumulative Data**: Use today's cumulative data as the base for tomorrow.

- **Strengths**
  - Efficient historical analysis without grouping.
  - Simplifies transition analysis.
  - Scalable queries as data is already accumulated.

- **Drawbacks**
  - Backfilling is sequential and cannot be parallelized.
  - Handling PII and data deletion requires careful management.
  - Tables grow larger over time, potentially leading to inefficiency.

## Compactness vs. Usability Trade-off

- **Understanding the Trade-off**
  - **Most Usable Tables**
    - Flat, straightforward structures.
    - Easy to query and understand.
    - Preferred by analysts and data scientists.
  - **Most Compact Tables**
    - Highly compressed.
    - Use complex data types or raw bytes.
    - Efficient for storage and transmission but harder to use.

- **Middle Ground**
  - Using complex data types like structs, arrays, and maps.
  - Balances compactness with usability.
  - Suitable for master data consumed by data engineers.

- **Considerations**
  - The needs of the data consumer dictate the modeling approach.
  - Complex data types are acceptable if consumers can handle them.
  - Usability is critical for analytical purposes.

## Complex Data Types

- **Struct**
  - Similar to a table within a table.
  - Contains a set of key-value pairs with defined data types.
  - Fields can have different data types.
  - Good for grouping related attributes.

- **Array**
  - A list of elements of the same data type.
  - Ordered collection.
  - Useful for representing lists or sequences.
  - Can contain complex types like structs or maps.

- **Map**
  - A collection of key-value pairs.
  - Keys are unique.
  - Values must be of the same data type.
  - Flexible for varying attributes.

- **Nesting Complex Types**
  - Arrays of structs or maps.
  - Structs containing arrays or other structs.
  - Enables modeling of hierarchical or multi-dimensional data.

## Temporal Cardinality Explosion

- **Challenges**
  - Temporal dimensions can greatly increase data size.
  - Example: Modeling listing availability over future dates leads to billions of rows.

- **Modeling Approaches**
  - **Flattened Data**
    - Each combination of entity and time unit is a separate row.
    - Leads to very large data sets.
  - **Using Arrays and Structs**
    - Store temporal data within arrays in a single row per entity.
    - Reduces data duplication and storage needs.

- **Compression Techniques**
  - **Run-Length Encoding**
    - Compresses sequences of repeating values.
    - Works well with sorted data.
    - Significantly reduces data size.

- **Impact of Joins and Shuffles**
  - Joins can disrupt data sorting.
  - Disrupted sorting reduces compression efficiency.
  - Modeling data to preserve sorting is crucial.

## Run-Length Encoding (RLE)

- **Definition**
  - A compression technique that replaces consecutive identical values with a single value and count.
  - Effective for data with many repeated values.

- **How RLE Works**
  - Identifies runs of the same value.
  - Stores the value and the number of times it repeats.
  - Example:
    - Data: `A, A, A, B, B, C`
    - RLE: `(A,3), (B,2), (C,1)`

- **Benefits in Data Modeling**
  - Reduces storage requirements.
  - Improves query performance due to reduced data size.
  - Particularly effective with sorted data.

- **Challenges with RLE**
  - Data shuffling during joins can break sorting.
  - Broken sorting reduces RLE effectiveness.
  - Solutions:
    - Avoid shuffling by using complex data types.
    - Preserve sorting through careful data modeling.

## Practical Applications

- **Airbnb Example**
  - Modeling listing availability as an array of structs.
  - Shrunk data sets by over 95%.
  - Allowed efficient storage and querying of availability data.

- **Player Seasons Example**
  - Storing player data with seasons in arrays.
  - Preserves sorting and enables RLE.
  - Avoids data duplication and storage bloat.

## Conclusion

- **Key Takeaways**
  - Data modeling requires understanding both data structures and user needs.
  - Choosing the right balance between compactness and usability is critical.
  - Complex data types can greatly enhance data efficiency when used appropriately.
  - Cumulative table design is powerful for historical and transition analyses.
  - Run-length encoding is a valuable tool for compressing large data sets.

- **Final Thoughts**
  - Modeling data effectively can lead to significant performance improvements.
  - Empathy towards data consumers ensures the data is usable and valuable.
  - Continuous learning and adaptation are essential in data engineering.

---

By organizing the lecture content into this markdown mindmap, we've covered all the key concepts and details presented, ensuring nothing is missed. This structure allows for easy review and understanding of the material.
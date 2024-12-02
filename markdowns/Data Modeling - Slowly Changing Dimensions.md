# Data Modeling - Slowly Changing Dimensions and Idempotency - Day 2 Lecture

## Introduction

- **Welcome to Dimensional Data Modeling Day Two Lecture**
- **Topics Covered**:
  - Slowly Changing Dimensions (SCD)
  - Idempotency in Data Pipelines
- **Objective**:
  - Understand how to model dimensions that change over time.
  - Learn the importance of idempotent pipelines in maintaining data quality.

## Idempotent Pipelines

### Definition of Idempotency

- **Mathematical Definition**:
  - An element remains unchanged when operated on by itself.
  - Example: `f(f(x)) = f(x)`
- **In Data Engineering**:
  - A pipeline that produces the same results regardless of:
    - When it is run.
    - How many times it is run.
    - The context in which it is run (production or backfill).
  - **Key Concept**: Consistency of outputs given the same inputs.

### Importance in Data Engineering

- **Data Quality**:
  - Ensures reproducibility of data.
  - Builds trust in data accuracy among analytics teams.
- **Troubleshooting**:
  - Easier to identify and fix issues when outputs are consistent.
- **Downstream Impact**:
  - Prevents inconsistencies from propagating to downstream data pipelines and analyses.

### Common Mistakes Leading to Non-Idempotent Pipelines

#### 1. Using `INSERT INTO` Without `TRUNCATE`

- **Issue**:
  - Running the pipeline multiple times duplicates data.
- **Example**:
  - First run inserts data for the day.
  - Subsequent runs insert duplicate records.
- **Solution**:
  - Use `MERGE` or `INSERT OVERWRITE` instead.
    - **`MERGE`**:
      - Merges new data with existing data.
      - Prevents duplication.
    - **`INSERT OVERWRITE`**:
      - Overwrites existing data in the partition.
      - Ensures only the latest data is present.

#### 2. Using `START_DATE >` Without Corresponding `END_DATE <`

- **Issue**:
  - Query retrieves an ever-increasing data range.
- **Example**:
  - Query: `WHERE date > '2021-01-01'`
  - Over time, the amount of data grows, affecting consistency.
- **Result**:
  - Data changes depending on when the pipeline is run.
- **Solution**:
  - Always specify both start and end dates to define a fixed window.
  - Example: `WHERE date > '2021-01-01' AND date <= '2021-01-07'`

#### 3. Not Using a Full Set of Partition Sensors

- **Issue**:
  - Pipeline runs before all input data is available.
- **Result**:
  - Outputs are incomplete and vary depending on run time.
- **Solution**:
  - Implement checks to ensure all necessary input partitions are present before running the pipeline.

#### 4. Depends on Past (Sequential Processing)

- **Issue**:
  - Pipelines rely on previous outputs (e.g., cumulative tables).
  - Backfilling cannot be parallelized.
- **Result**:
  - Inconsistent outputs when backfilling or running in parallel.
- **Solution**:
  - Design pipelines to process data independently when possible.
  - For cumulative pipelines, enforce sequential processing during backfills.

### Issues Caused by Non-Idempotent Pipelines

- **Hard to Troubleshoot**:
  - No obvious errors; issues are silent.
- **Data Discrepancies**:
  - Analysts notice mismatched numbers across tables.
- **Loss of Trust**:
  - Users lose confidence in data accuracy.
- **Propagation of Errors**:
  - Inconsistencies affect downstream pipelines and analyses.
- **Backfill Challenges**:
  - Backfills produce different results from original runs.
- **Example**:
  - A data pipeline that depends on the latest data may produce different outputs when rerun, causing confusion and errors.

### Real-World Example: Facebook Fake Accounts

- **Context**:
  - Building a model to track fake accounts and their state transitions.
- **Problem**:
  - The `dim_all_fake_accounts` table was non-idempotent.
  - It sometimes used today's data and other times used yesterday's data, depending on availability.
- **Impact**:
  - Inconsistent results in analyses.
  - Difficult to troubleshoot and identify the root cause.
- **Lesson**:
  - Prioritizing data latency over data quality can lead to significant issues.
  - Ensuring idempotency is crucial for reliable data pipelines.

## Slowly Changing Dimensions (SCD)

### What is a Slowly Changing Dimension?

- **Definition**:
  - A dimension whose attributes change over time, albeit infrequently.
- **Examples**:
  - **Age**: Increases annually.
  - **Favorite Food**: Personal preferences change over years.
  - **Country of Residence**: People may relocate to different countries.
  - **Phone Type**: Switching from Android to iPhone or vice versa.

### Types of Dimensions

- **Fixed Dimensions**:
  - Attributes that do not change.
  - Example: Date of birth, eye color (generally).
- **Slowly Changing Dimensions**:
  - Attributes that change over time.
  - Require modeling to track historical values.
- **Rapidly Changing Dimensions**:
  - Attributes that change frequently.
  - Example: Heart rate, stock prices.

### Modeling Slowly Changing Dimensions

#### Challenges

- **Maintaining Historical Accuracy**:
  - Need to reflect the dimension's value at any point in time.
- **Idempotency**:
  - Ensuring that historical data remains consistent over time.

#### Approaches to Modeling

##### 1. Latest Snapshot

- **Description**:
  - Only the most recent value is stored.
- **Issues**:
  - Backfills overwrite historical values with the latest data.
  - Historical analyses become inaccurate.
- **Recommendation**:
  - **Avoid using this approach** for dimensions that change over time.

##### 2. Daily Partition Snapshots

- **Description**:
  - Store the dimension's value for each day.
- **Advocated by**:
  - Maxime Beauchemin (creator of Apache Airflow).
- **Benefits**:
  - Simplicity in implementation.
  - Ensures idempotency by associating dimensions with specific dates.
- **Trade-offs**:
  - Increased storage due to data duplication.
  - Storage is relatively cheap compared to the cost of data inaccuracies.

##### 3. Slowly Changing Dimension Types

###### a. SCD Type 0

- **Description**:
  - The dimension is considered fixed.
- **Use Case**:
  - Attributes that truly never change.
- **Idempotency**:
  - Naturally idempotent.

###### b. SCD Type 1

- **Description**:
  - Overwrite old data with new data.
- **Issues**:
  - Loss of historical data.
  - Not idempotent.
- **Recommendation**:
  - Not suitable for analytical purposes where history matters.

###### c. SCD Type 2 (Preferred Method)

- **Description**:
  - Tracks historical changes by creating multiple records with start and end dates.
- **Implementation**:
  - **Columns**:
    - **Start Date**: When the attribute value became effective.
    - **End Date**: When the attribute value ceased to be effective.
    - **Current Record Indicator**: (Optional) Boolean flag to indicate the current record.
  - **Example**:
    - Favorite food from 2000 to 2008: Lasagna.
    - Favorite food from 2008 onwards: Curry.
- **Advantages**:
  - Maintains complete history of changes.
  - Allows querying the dimension at any point in time.
  - Ensures idempotency.
- **Handling Current Records**:
  - Use a far-future date for the end date (e.g., '9999-12-31').
  - Alternatively, use `NULL` for the end date.

###### d. SCD Type 3

- **Description**:
  - Stores only the original and current values.
- **Issues**:
  - Limited to tracking a single change.
  - Loses history if the attribute changes multiple times.
- **Idempotency**:
  - Not idempotent when multiple changes occur.
- **Recommendation**:
  - Generally not recommended due to its limitations.

###### e. Other Types (SCD Type 4, 5, 6)

- **Note**:
  - More complex and less commonly used.
  - Often involve hybrid approaches.

### Debate on Modeling Approaches

#### Max's Perspective

- **Viewpoint**:
  - Prefers daily snapshots (functional data engineering).
  - Argues that SCDs are inherently non-idempotent.
- **Rationale**:
  - Emphasizes simplicity and functional purity.
  - Storage costs are negligible compared to data accuracy.

#### Zach's Perspective

- **Viewpoint**:
  - Supports using SCD Type 2.
  - Values the compression and efficiency of SCD Type 2.
- **Rationale**:
  - Provides complete historical context.
  - Efficient in terms of storage when dimensions change infrequently.
  - Believes that SCD Type 2 can be idempotent when implemented correctly.

### Loading SCD Type 2 Tables

#### Methods

##### 1. Full Reload (One Giant Query)

- **Description**:
  - Processes the entire dataset each time the pipeline runs.
- **Pros**:
  - Simplicity in pipeline design.
- **Cons**:
  - Inefficient for large datasets.
  - High computational resource usage.

##### 2. Incremental Loading (Cumulative Approach)

- **Description**:
  - Processes only new or changed data since the last run.
- **Pros**:
  - More efficient for large datasets.
  - Reduces processing time and resource consumption.
- **Cons**:
  - Slightly more complex to implement.
- **Recommendation**:
  - Preferred in production environments for efficiency.

#### Practical Considerations

- **Dataset Size**:
  - For small datasets, full reloads may be acceptable.
- **Resource Availability**:
  - Incremental loading conserves resources.
- **Business Priorities**:
  - Focus on delivering value rather than micro-optimizations.
- **Example**:
  - At Airbnb, the unit economics pipeline processed all data daily.
  - Although incremental loading was more efficient, the business value of optimizing was low compared to other priorities.

## Career Advice

- **Prioritize Impact**:
  - Focus on projects that deliver significant business value.
- **Avoid Over-optimization**:
  - Do not spend excessive time on marginal efficiency gains.
- **Opportunity Cost**:
  - Consider what other valuable tasks could be accomplished with the time spent on optimization.
- **Balance Efficiency and Practicality**:
  - Aim for efficient solutions, but not at the expense of more critical work.

---

## Are You Missing Anything Else About Data Modeling?

Based on the above discussion, you've covered important aspects of data modeling related to slowly changing dimensions and idempotency in data pipelines. These are crucial topics in ensuring data quality and consistency in analytical environments.

However, data modeling is a broad field with many other important concepts and techniques. Here are some additional areas you might consider exploring to deepen your understanding:

1. **Entity-Relationship (ER) Modeling**:
   - **Concept**: Visual representation of data entities, their attributes, and relationships.
   - **Application**: Fundamental in designing relational databases.

2. **Normalization and Denormalization**:
   - **Normalization**:
     - Organizing data to reduce redundancy and improve integrity.
     - Involves applying normal forms (1NF, 2NF, 3NF, etc.).
   - **Denormalization**:
     - Combining tables to improve read performance.
     - Often used in OLAP systems.

3. **Data Warehousing Schemas**:
   - **Star Schema**:
     - Central fact table connected to dimension tables.
     - Simplifies complex queries and improves performance.
   - **Snowflake Schema**:
     - Extension of star schema with normalized dimensions.
     - Reduces redundancy but can complicate queries.

4. **Fact and Dimension Tables**:
   - **Fact Tables**:
     - Store quantitative data for analysis.
   - **Dimension Tables**:
     - Store descriptive attributes to filter and group facts.

5. **Dimensional Modeling Techniques**:
   - **Conformed Dimensions**:
     - Shared dimensions across different fact tables.
   - **Junk Dimensions**:
     - Combine low-cardinality flags and indicators into a single dimension.

6. **Data Vault Modeling**:
   - **Concept**:
     - Agile and scalable data modeling approach.
   - **Components**:
     - Hubs, Links, and Satellites.
   - **Benefits**:
     - Facilitates auditing and historical tracking.

7. **NoSQL Data Modeling**:
   - **Document Databases**:
     - Example: MongoDB.
   - **Key-Value Stores**:
     - Example: Redis.
   - **Column-Family Stores**:
     - Example: Apache Cassandra.
   - **Graph Databases**:
     - Example: Neo4j.

8. **Temporal Data Modeling**:
   - **Bitemporal Modeling**:
     - Tracks both valid time and transaction time.
   - **Applications**:
     - Useful in financial systems and compliance.

9. **Master Data Management (MDM)**:
   - **Concept**:
     - Processes for defining and managing critical data.
   - **Goal**:
     - Provide a single source of truth across the organization.

10. **Data Lineage and Governance**:
    - **Data Lineage**:
      - Tracking data's origin and transformations.
    - **Data Governance**:
      - Policies and procedures to manage data assets.

11. **Performance Optimization**:
    - **Indexing Strategies**:
      - Improving query performance with appropriate indexes.
    - **Partitioning and Sharding**:
      - Distributing data across multiple storage units.

12. **Big Data Technologies**:
    - **Hadoop Ecosystem**:
      - Understanding HDFS, MapReduce, Hive, etc.
    - **Distributed Databases**:
      - Working with systems like Apache HBase.

13. **Real-Time Data Processing**:
    - **Streaming Data**:
      - Tools like Apache Kafka and Spark Streaming.
    - **Event-Driven Architectures**:
      - Designing systems to handle real-time events.

14. **Data Modeling in Cloud Environments**:
    - **Cloud Databases**:
      - Amazon Redshift, Google BigQuery, Azure Synapse.
    - **Scalability and Elasticity**:
      - Designing models that leverage cloud capabilities.

15. **Advanced SQL Techniques**:
    - **Window Functions**:
      - Performing calculations across sets of rows.
    - **Common Table Expressions (CTEs)**:
      - Simplifying complex queries.
    - **Recursive Queries**:
      - Working with hierarchical data.

16. **Data Security and Compliance**:
    - **Encryption and Access Control**:
      - Protecting sensitive data.
    - **Regulatory Compliance**:
      - GDPR, HIPAA, and other regulations impacting data modeling.

17. **Graph Data Modeling**:
    - **Concept**:
      - Modeling data based on nodes and relationships.
    - **Use Cases**:
      - Social networks, recommendation engines.

18. **Data Modeling Tools and Best Practices**:
    - **Tools**:
      - ERwin, Lucidchart, PowerDesigner.
    - **Documentation**:
      - Maintaining data dictionaries and model descriptions.

19. **Agile Data Modeling**:
    - **Iterative Development**:
      - Evolving data models alongside application development.
    - **Collaboration**:
      - Engaging stakeholders throughout the modeling process.

20. **Machine Learning Data Requirements**:
    - **Feature Engineering**:
      - Preparing data for ML models.
    - **Data Quality for ML**:
      - Ensuring consistency and accuracy for training data.

Exploring these areas will enhance your understanding of data modeling and its applications across different domains. Each topic offers valuable insights and can be crucial depending on the specific needs of your projects or organization.

**Next Steps**:

- **Identify Areas of Interest**:
  - Choose topics that align with your current or future projects.
- **Deep Dive**:
  - Take courses or read books focused on those areas.
- **Practical Application**:
  - Apply new concepts to real-world scenarios to reinforce learning.
- **Join Communities**:
  - Engage with data modeling forums or groups to share knowledge and experiences.

Feel free to ask if you need more information or guidance on any of these topics!
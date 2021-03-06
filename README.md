# Batch pipeline for checkout.com 
## High level schema diagram
Below is a simple model of the data warehouse schemas (in this case - Google BigQuery) used to support the BI tool activity on pageviews.
![dwh-model](https://github.com/yag101/dbt-batch-pipeline-checkout/blob/master/dwh-model.png?raw=true)
The two raw feeds (users_extract and pageviews_extract) have already been generated by the engineering team and already exist in the date warehouse. They will be joined together on the user id field, also drawing in the dates/times at which they were extracted, as part of the transformation process. This will be incrementally loaded every hour into a single table called pageviews_enhanced.

The final part of the process will materialise two different tables, based on the complete pageviews_enhanced table, which will enable the team to performantly answer any questions on the number of pageviews by postcode by time/date. One table will feature the total count of the number of pageviews for each postcode, by hour. The other table will also feature the total count of pageviews, but grouped by the most recent postcode of a user - given by joining the raw extract table users_extract onto our enhanced table pageviews_enhanced.

## Transform pipeline and schemas
Inside the /models/batch/ directory of this GitHub project, I have stored the relevant dbt sql transform jobs. The first part of the process described earlier is represented by the dbt model file pageviews_enhanced.sql, which acts as a prerequisite to the other two dbt model files pageviews_by_pageviewpostcode.sql and pageviews_by_currentpostcode.sql.

The relevant schemas are stored in this same directory, in the schema.yml file.

## Scheduling the transform pipeline
There are a number of different ways in which this dbt job can be scheduled. Using dbt, the simplest method would be to use dbt cloud's built-in scheduling service, which acts as a sort of frontend for the popular time-based job scheduling utility knwon as 'cron', with some added job history and logging capabilities. Further information can be found [here](https://docs.getdbt.com/docs/running-a-dbt-project/running-dbt-in-production/#using-dbt-cloud).

In this instance - I would invoke the command 'dbt run' on this project, which will generate the relevant tables directly in the data warehouse which is connected to this project (in this case Google BigQuery). I would assign the following cron schedule:
0 * * * *
This means that the scheduled task will run on the hour (in the 0th minute) every hour. Altering the '0' here will change the minute which the scheduled task will run in. For example, if I change the cron schedule to instead be ' 5 * * * * ', the job will instead run in the 5th minute of each hour, which could be done to accommodate for potential delays to the raw extracts' arrival in the data warehouse.

## Running the pipeline
Once relevant permissions have been granted and the user has access to the project which contains the dbt models, they can simply be invoked with the command 'dbt run'. For an initial clean run, consider instead using the command 'dbt run --full-refresh' for the inital run. As the model generates an incrementally loaded table, doing a 'full-refresh' will treat it instead as a fresh new table, truncating the existing data and doing a fresh load with the raw extract data.

## Querying the final tables
After the transform process is complete, two new tables will appear in the defined target area in the data warehouse - 'pageviews_by_currentpostcode' and 'pageviews_by_pageviewpostcode'.

To answer the two key BI questions regarding the number of pageviews, the grouping of the total number of pageviews by each type of postcode has been materialised into each table. It has been materialised at the most granular level by time - in this case, by each hour.

To convert this time into a different format, e.g. Month-Year, a simple SQL conversion can be written - see the example below.
```
    SELECT
    pageview_hour,
      FORMAT_DATETIME("%b-%y", pageview_hour)
    FROM
      `tp-appmaker.dbt_Checkout_target.pageviews_by_currentpostcode`
```
This convert the pageview hour (in DATETIME format) to the format of abbreviated month and year - e.g. converting the DATETIME of '2020-09-02T07:00:00' to 'Sep-20'.

The syntax for `FORMAT_DATETIME` works like so:
`FORMAT_DATETIME(format_string, datetime_expression)`
Where `format_string` represents the desired format you wish the original datetime to appear in. It is possible to construct this from a set of valid format elements. Please refer to the [list of supported format elements here](https://cloud.google.com/bigquery/docs/reference/standard-sql/datetime_functions#supported_format_elements_for_datetime).

Using this date conversion, the team are able to simply and performantly group and compare the total pageviews by postcode to fit the requirements for any given date/time comparison of their choice.

{{ config(
  materialized='table'
) }}
--Materialises the final query as a table to improve performance for the end user

WITH
  users AS (
  SELECT
    id,
    postcode -- Pulling in the current postcode from the most recent version of the users extract
  FROM
    `tp-appmaker.dbt_Checkout.users_extract` ),
    
  pageviews AS (
  SELECT
    user_id,
    url,
    t1.postcode AS current_postcode, -- Taking the current postcode from the users_extract as it exists now
    pageview_extractdatetime
  FROM
    {{ ref('pageviews_enhanced') }} t0 -- From the incremental table we generated earlier
  LEFT JOIN
    users t1
  ON
    t0.user_id = t1.id)

SELECT
  COUNT(*) AS pageviews,
  current_postcode,
  pageview_extractdatetime AS pageview_hour

FROM
  pageviews
GROUP BY
  current_postcode,
  pageview_extractdatetime
-- A count of the number of pageviews per hour, by the current postcode of a user

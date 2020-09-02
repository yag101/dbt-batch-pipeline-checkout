{{ config(materialized='incremental' ) }}
--Implements an incremental load model
WITH
  users AS (
  SELECT
    *,
    DATETIME_SUB(DATETIME(CURRENT_DATE(),
        "00:00:00"),
      INTERVAL 1 DAY) AS user_extractdatetime
      -- Takes midnight from the previous day to infer when the user data was last updated
  FROM
    `tp-appmaker.dbt_Checkout.users_extract` ),
    
  pageviews AS (
  SELECT
    *,
    DATETIME_SUB(DATETIME_TRUNC(CURRENT_DATETIME(),
        HOUR),
      INTERVAL 1 HOUR) AS pageview_extractdatetime
      -- Truncates the current time to the hour, subtracting 1 hour to infer the hour of the page view
  FROM
    `tp-appmaker.dbt_Checkout.pageviews_extract` )
    
SELECT
  user_id,
  url,
  postcode AS pageview_postcode, --The postcode of the user viewing the page is stored at this point
  user_extractdatetime,
  pageview_extractdatetime
FROM
  pageviews t0
LEFT JOIN
  users t1
ON
  t0.user_id = t1.id

WHERE pageview_extractdatetime > (select max(pageview_extractdatetime) from {{ this }})
-- Ensures that duplicate data is not loaded if the pageviews_extract fails to be truncated/reloaded
